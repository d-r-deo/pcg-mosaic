function [yAxesFinal, allHandles, allYAxes] = general_mPCA_plot( out, timeAxis, lineArgs, margNamesShort, ...
    axisType, bgSignal, forceAxes, dimCI, ciColors, plotCI, layoutInfo)

    margOrder = unique(out.whichMarg);
    nMarg = length(unique(out.whichMarg));
    if nargin<10
        layoutInfo = [];
    end
    if isempty(layoutInfo)
        nPerMarg = 7;
        fPos = [573, 195, 1575*(nPerMarg/7), 847];
        colorFactor = 1;
        textLoc = [0.7,0.1];
        plotLayout = 'vertical';
        subplotMarginGap = [0.03 0.01];
        subplotMarginWidth = [0.05 0.02];
        subplotMarginHeight = [0.07 0.02];
        verticalBars = [0,1.5];
    else
        nPerMarg = layoutInfo.nPerMarg;
        fPos = layoutInfo.fPos;
        colorFactor = layoutInfo.colorFactor;
        textLoc = layoutInfo.textLoc;
        plotLayout = layoutInfo.plotLayout;
        subplotMarginGap = layoutInfo.gap;
        subplotMarginWidth = layoutInfo.marg_h;
        subplotMarginHeight = layoutInfo.marg_w;
        verticalBars = layoutInfo.verticalBars;
    end
    allYAxes = cell(nMarg,1);
    
    if nargin<6
        bgSignal = [];
    end
    if nargin<7
        forceAxes = [];
    end
    if nargin<10
        timeBar = [];
    end
    
    nFactors = ndims(out.Z)-2;
    
    allHandles = cell(nMarg, 1);
    figure('Position',fPos);
    for n=1:nMarg
        yAxesAll = [];
        axHandles = [];
        margIdx = find(out.whichMarg==margOrder(n));
        if length(margIdx)==0
            continue;
        end
        for p=1:nPerMarg
            if p>length(margIdx)
                break;
            end
            if strcmp(plotLayout,'vertical')
                subtightplot(nMarg, nPerMarg, (n-1)*nPerMarg + p,subplotMarginGap,subplotMarginHeight,subplotMarginWidth);
            else
                subtightplot(nPerMarg, nMarg, (p-1)*nMarg + n,subplotMarginGap,subplotMarginHeight,subplotMarginWidth);
            end
            hold on;
            
            %plot a line for each condition
            sz = size(out.Z);
            sz = sz(2:(end-1));
            subIdx = cell(length(sz),1);
            for factorIdx=1:prod(sz)
                [subIdx{:}] = ind2sub(sz, factorIdx);
                
                readOp = ['(margIdx(p)'];
                for x=1:length(subIdx)
                    readOp = [readOp, ',' num2str(subIdx{x})];
                end
                readOp = [readOp ',:)'];
                dat = squeeze(eval(['out.Z' readOp]));
                
                plot(timeAxis, dat, lineArgs{factorIdx}{:});
                if ~isempty(dimCI)
                    readOpCI = ['(margIdx(p)'];
                    for x=1:length(subIdx)
                        readOpCI = [readOpCI, ',' num2str(subIdx{x})];
                    end
                    readOpCI = [readOpCI ',:,:)'];
                
                    lineColor = findColorArg(lineArgs{factorIdx});
                    if ~isnan(lineColor)
                        patchColor = lineColor;
                    else
                        patchColor = ciColors(factorIdx,:);
                    end
                    ciDat = squeeze(eval(['dimCI' readOpCI]));
                    
                    if plotCI
                        errorPatch( timeAxis', ciDat, patchColor, 0.2 );
                    end
                end
            end
                      
            %axis labeling and management
            if strcmp(plotLayout,'vertical')
                if n~=nMarg
                    set(gca,'XTickLabel',[]);
                else
                    xlabel('Time (s)');
                end
                if p==1
                    ylabel(margNamesShort{n});
                else
                    set(gca,'YTickLabel',[]);
                end
            else
                if p==nPerMarg
                    xlabel('Time (s)');
                else
                    set(gca,'XTickLabel',[]);
                end
                if p==1
                    title(margNamesShort{n});
                end
                if n>1
                    set(gca,'YTickLabel',[]);
                end
            end
            
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlim([timeAxis(1), timeAxis(end)]);
            axHandles = [axHandles; gca];
            axis tight;
            yAxesAll = [yAxesAll; get(gca,'YLim')];
            
            if isfield(out,'componentVarNumber')
                text(textLoc(1),textLoc(2)+0.13,['#' num2str(out.componentVarNumber(margIdx(p)),2)],'Units','normalized','FontSize',18);
            end
            if isfield(out,'explVar')
                text(textLoc(1),textLoc(2),[num2str(out.explVar.margVar(n,margIdx(p)),3) '%'],'Units','normalized','FontSize',18);
            end
            if isfield(out,'sepScore')
                text(textLoc(1),textLoc(2)-0.13,[num2str(out.sepScore(margIdx(p)),2)],'Units','normalized','FontSize',18);
            end
            
            set(gca,'FontSize',18);
        end
        
        if ~isempty(forceAxes)
            yAxesFinal = forceAxes;
        else
            yAxesFinal = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        end
        allYAxes{n} = yAxesFinal;
        if strcmp(axisType,'sameAxes') || strcmp(axisType,'sameAxesGlobal')
            for axIdx = 1:length(axHandles)
                set(axHandles(axIdx), 'YLim', yAxesFinal);
            end
        end
        
        %plot zero ones
        for axIdx = 1:length(axHandles)
            if ~isempty(bgSignal)
                axes(axHandles(axIdx));
                plotBackgroundSignal( timeAxis, bgSignal );
            end
        end
        allHandles{n} = axHandles;
    end
    
    if strcmp(axisType,'sameAxesGlobal')
        yAxesAll = vertcat(allYAxes{:});
        yAxesFinal = [min(yAxesAll(:,1)), max(yAxesAll(:,2))];
        for n=1:nMarg
            for axIdx = 1:length(allHandles{n})
                set(allHandles{n}(axIdx), 'YLim', yAxesFinal);
            end
        end
    end
    for n=1:nMarg
        for axIdx = 1:length(allHandles{n})
            if timeAxis(end)>0
                yLimits = get(allHandles{n}(axIdx),'YLim');
                for x=1:length(verticalBars)
                    plot(allHandles{n}(axIdx), [verticalBars(x), verticalBars(x)], yLimits, '--k','LineWidth',2);
                end
            end
        end
    end
end

function lineColor = findColorArg(lineArgs)
    lineColor = nan;
    for x=1:length(lineArgs)
        if strcmp(lineArgs{x},'Color')
            lineColor = lineArgs{x+1};
            return;
        end
    end
end

