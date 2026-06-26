import os
import pickle
import time

import hydra
import numpy as np
import torch
from torch.nn.utils.rnn import pad_sequence
from torch.utils.data import DataLoader

from model import GRUDecoder
from dataset import MovementDataset


def levenshtein_distance(a, b):
    if len(a) < len(b):
        a, b = b, a

    previous = list(range(len(b) + 1))
    for i, a_item in enumerate(a, start=1):
        current = [i]
        for j, b_item in enumerate(b, start=1):
            insert_cost = current[j - 1] + 1
            delete_cost = previous[j] + 1
            substitute_cost = previous[j - 1] + (a_item != b_item)
            current.append(min(insert_cost, delete_cost, substitute_cost))
        previous = current
    return previous[-1]


def getDatasetLoaders(
    datasetName,
    batchSize,
):
    with open(datasetName, "rb") as handle:
        loadedData = pickle.load(handle)

    def _padding(batch):
        X, y, X_lens, y_lens, days = zip(*batch)
        X_padded = pad_sequence(X, batch_first=True, padding_value=0)
        y_padded = pad_sequence(y, batch_first=True, padding_value=0)

        return (
            X_padded,
            y_padded,
            torch.stack(X_lens),
            torch.stack(y_lens),
            torch.stack(days),
        )

    train_ds = MovementDataset(loadedData["train"], transform=None)
    test_ds = MovementDataset(loadedData["test"])

    train_loader = DataLoader(
        train_ds,
        batch_size=batchSize,
        shuffle=True,
        num_workers=0,
        pin_memory=True,
        collate_fn=_padding,
    )
    test_loader = DataLoader(
        test_ds,
        batch_size=batchSize,
        shuffle=False,
        num_workers=0,
        pin_memory=True,
        collate_fn=_padding,
    )

    return train_loader, test_loader, loadedData

def autoDetectDevice():
    """Pick the best available compute device for training/inference."""
    if torch.cuda.is_available():
        return "cuda"
    if getattr(torch.backends, "mps", None) is not None and torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def trainModel(args):
    os.makedirs(args["outputDir"], exist_ok=True)
    torch.manual_seed(args["seed"])
    np.random.seed(args["seed"])
    device = args.get("device") if args.get("device") else autoDetectDevice()
    print(f"Using device: {device}")

    with open(args["outputDir"] + "/args", "wb") as file:
        pickle.dump(args, file)

    trainLoader, testLoader, loadedData = getDatasetLoaders(
        args["datasetPath"],
        args["batchSize"],
    )

    model = GRUDecoder(
        neural_dim=args["nInputFeatures"],
        n_classes=args["nClasses"],
        hidden_dim=args["nUnits"],
        layer_dim=args["nLayers"],
        nDays=len(loadedData["train"]),
        dropout=args["dropout"],
        device=device,
        strideLen=args["strideLen"],
        kernelLen=args["kernelLen"],
        gaussianSmoothWidth=args["gaussianSmoothWidth"],
        bidirectional=args["bidirectional"],
    ).to(device)

    loss_ce = torch.nn.CrossEntropyLoss()
    loss_ctc = torch.nn.CTCLoss(blank=0, reduction="mean", zero_infinity=True)
    
    optimizer = torch.optim.Adam(
        model.parameters(),
        lr=args["lrStart"],
        betas=(0.9, 0.999),
        eps=0.1,
        weight_decay=args["l2_decay"],
    )
    
    scheduler = torch.optim.lr_scheduler.LinearLR(
        optimizer,
        start_factor=1.0,
        end_factor=args["lrEnd"] / args["lrStart"],
        total_iters=args["nBatch"],
    )

    # --train--
    testLoss = []
    testCER = []
    testClassAcc = []
    
    startTime = time.time()
    for batch in range(args["nBatch"]):
        model.train()

        X, y, X_len, y_len, dayIdx = next(iter(trainLoader))
        X, y, X_len, y_len, dayIdx = (
            X.to(device),
            y.to(device),
            X_len.to(device),
            y_len.to(device),
            dayIdx.to(device),
        )

        # Noise augmentation is faster on GPU
        if args["whiteNoiseSD"] > 0:
            X += torch.randn(X.shape, device=device) * args["whiteNoiseSD"]

        if args["constantOffsetSD"] > 0:
            X += (
                torch.randn([X.shape[0], 1, X.shape[2]], device=device)
                * args["constantOffsetSD"]
            )

        # Compute prediction error
        pred = model.forward(X, dayIdx)

        if args["crossEntropyLoss"] > 0:
            loss = loss_ce(torch.mean(pred, dim=1)[:,1:], y[:,0].to(torch.int64)) #y[:,0].type(torch.LongTensor).to(device))
        else:
            loss = loss_ctc(
                torch.permute(pred.log_softmax(2), [1, 0, 2]),
                y,
                ((X_len - model.kernelLen) / model.strideLen).to(torch.int32),
                y_len,
            )
            
        loss = torch.sum(loss)

        # Backpropagation
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        scheduler.step()

        # print(endTime - startTime)

        # Eval
        if batch % 100 == 0:
            with torch.no_grad():
                model.eval()
                allLoss = []
                total_edit_distance = 0
                total_seq_length = 0
                total_trials = 0
                total_hits = 0
                for X, y, X_len, y_len, testDayIdx in testLoader:
                    X, y, X_len, y_len, testDayIdx = (
                        X.to(device),
                        y.to(device),
                        X_len.to(device),
                        y_len.to(device),
                        testDayIdx.to(device),
                    )

                    pred = model.forward(X, testDayIdx)
                    
                    if args["crossEntropyLoss"] > 0:
                        loss = loss_ce(torch.mean(pred, dim=1)[:,1:], y[:,0].to(torch.int64)) 
                    else:
                        loss = loss_ctc(
                            torch.permute(pred.log_softmax(2), [1, 0, 2]),
                            y,
                            ((X_len - model.kernelLen) / model.strideLen).to(torch.int32),
                            y_len,
                        )
                        loss = torch.sum(loss)
                        
                    allLoss.append(loss.cpu().detach().numpy())
                    
                    #if testDayIdx==0:
                    #from IPython.display import clear_output
                    #import matplotlib.pyplot as plt
                    #clear_output(wait=False)

                    #plt.figure()
                    #plt.plot(pred.cpu().detach().numpy()[0,:,:])
                    #plt.show()
                    
                    #maxOut = torch.max(pred.softmax(2)[:,:,1:], dim=1)
                    #px = torch.max(maxOut[0],dim=1)
                    #px = px[1]

                    if args["crossEntropyLoss"]:
                        px = torch.max(torch.mean(pred, dim=1)[:,1:], dim=1)
                        px = px[1]
                        #print(px)
                    else:
                        px = torch.max(pred[:,0,1:], dim=1)
                        px = px[1]+1
                    
                    #mn = torch.mean(pred[:,:,1:], dim=1)
                    #print(mn.shape)
                    #px = torch.argmax(mn,dim=1)
                    
                    px = px.cpu().detach().numpy()
                    yd = y.cpu().detach()[:,0].numpy()

                    total_hits += np.sum(px==yd)
                    total_trials += px.shape[0]
                    
                    if not args["crossEntropyLoss"]:
                        adjustedLens = ((X_len - model.kernelLen) / model.strideLen).to(
                            torch.int32
                        )
                        for iterIdx in range(pred.shape[0]):
                            decodedSeq = torch.argmax(
                                pred[iterIdx, 0 : adjustedLens[iterIdx], :].detach(),
                                dim=-1,
                            )
                            decodedSeq = torch.unique_consecutive(decodedSeq, dim=-1)
                            decodedSeq = decodedSeq.cpu().numpy()
                            decodedSeq = np.array([i for i in decodedSeq if i != 0])

                            trueSeq = np.array(
                                y[iterIdx][0 : y_len[iterIdx]].cpu().detach()
                            )

                            total_edit_distance += levenshtein_distance(
                                trueSeq.tolist(), decodedSeq.tolist()
                            )
                            total_seq_length += len(trueSeq)

                avgDayLoss = np.sum(allLoss) / len(testLoader)
                cer = (
                    total_edit_distance / total_seq_length
                    if total_seq_length > 0
                    else np.nan
                )
                classAcc = total_hits / total_trials 
                
                endTime = time.time()
                print(
                    f"batch {batch}, loss: {avgDayLoss:>7f}, cer: {cer:>7f}, acc: {classAcc:>7f}, time/batch: {(endTime - startTime)/100:>7.3f}"
                )
                startTime = time.time()

            if len(testClassAcc) > 0 and classAcc > np.max(testClassAcc):
                torch.save(model.state_dict(), args["outputDir"] + "/modelWeights")

            testLoss.append(avgDayLoss)
            testCER.append(cer)
            testClassAcc.append(classAcc)

            tStats = {}
            tStats["testLoss"] = np.array(testLoss)
            tStats["testCER"] = np.array(testCER)
            tStats["testClassAcc"] = np.array(testClassAcc)

            with open(args["outputDir"] + "/trainingStats", "wb") as file:
                pickle.dump(tStats, file)
                
    if args['saveWhenDone']:
        torch.save(model.state_dict(), args["outputDir"] + "/modelWeights")

    # Marker file written only after the full nBatch loop completes successfully.
    # The resume logic in 02_train_rnns.ipynb uses this (not modelWeights) to
    # detect truly-finished runs vs partially-trained leftovers.
    with open(args["outputDir"] + "/done", "w") as file:
        file.write("ok\n")

def loadModel(modelDir, nInputLayers=24, device=None):
    if device is None:
        device = autoDetectDevice()
    modelWeightPath = modelDir + "/modelWeights"
    with open(modelDir + "/args", "rb") as handle:
        args = pickle.load(handle)

    model = GRUDecoder(
        neural_dim=args["nInputFeatures"],
        n_classes=args["nClasses"],
        hidden_dim=args["nUnits"],
        layer_dim=args["nLayers"],
        nDays=nInputLayers,
        dropout=args["dropout"],
        device=device,
        strideLen=args["strideLen"],
        kernelLen=args["kernelLen"],
        gaussianSmoothWidth=args["gaussianSmoothWidth"],
        bidirectional=args["bidirectional"],
    ).to(device)

    model.load_state_dict(torch.load(modelWeightPath, map_location=device))
    return model


@hydra.main(version_base="1.1", config_path="conf", config_name="config")
def main(cfg):
    cfg.outputDir = os.getcwd()
    trainModel(cfg)

if __name__ == "__main__":
    main()