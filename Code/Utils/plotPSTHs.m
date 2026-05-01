function ret = plotPSTHs(sDat)
    fprintf('******* Computing PSTHs \n\n');
    
    if isfield(sDat,'plottingWindow')
        plottingWindow = sDat.plottingWindow;
        binWidth = sDat.binWidth;
    else
        plottingWindow = [-100 150];
        binWidth = 0.02;
    end

    if isfield(sDat,'gaussSmoothWidth')
        gaussSmoothWidth = sDat.gaussSmoothWidth;
    else
        gaussSmoothWidth = 6;
    end

    

        smoothFeat = gaussSmooth_fast(sDat.features, gaussSmoothWidth); % smooth features
        for setIdx=1:length(sDat.movementSets) % iterate through each movement set
            mkdir([sDat.saveDir filesep 'psth_' sDat.movementSetNames{setIdx}]); % create directory to store results from current movement set

            colors = jet(length(sDat.movementSets{setIdx}))*0.8; % colormap
            nPages = ceil(size(sDat.features,2)/64); % define number of pages to create to plot all channels in groups of 64
            featIdx = 1:64;
            for pageIdx=1:nPages
                figure('Units','Normalized','Position',[0    0.0463    1.0000    0.8667]);
                for f=1:length(featIdx)
                    if featIdx(f)>size(sDat.features,2)
                        continue;
                    end

                    subplot(8,8,f);
                    hold on;

                    ms = sDat.movementSets{setIdx};
                    for m=1:length(ms)
                        trlIdx = find(sDat.movementCodes==ms(m));
                        [ concatDat ] = triggeredAvg( smoothFeat(:,featIdx(f)), sDat.goTimes(trlIdx), plottingWindow );

                        timeAxis = (plottingWindow(1):plottingWindow(2))*binWidth;
                        plot(timeAxis, nanmean(concatDat),'Color',colors(m,:),'LineWidth',1);

                        [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
                        fHandle = errorPatch( timeAxis', MUCI', colors(m,:), 0.2 );
                    end
                    xlim([timeAxis(1), timeAxis(end)]);
                    plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);

                    title(featIdx(f));
                    if f>=57
                        xlabel('Time (s)');
                    end
                    if mod(f-1,8)==0
                        ylabel('Rate (Hz)');
                    end
                end

                if isfield(sDat, 'ylims')
                    ylim(sDat.ylims);
                end
                ret = gcf;
                exportPNGFigure(gcf, [sDat.saveDir filesep 'psth_' sDat.movementSetNames{setIdx} filesep 'psth_' num2str(pageIdx) '_' sDat.movementSetNames{setIdx}] );
                close all;

                featIdx = featIdx + length(featIdx);
            end

            

            %PSTH legend
            figure('Units','Normalized','Position',[0.3171    0.3833    0.1525    0.5094]);
            hold on;
            for m=1:length(ms)
                plot([0,1],[0,1],'-','Color',colors(m,:),'LineWidth',2);
            end
            xlim([2 3]); ylim([2 3]);
            axis off;
            legend(sDat.movementNames(sDat.movementSets{setIdx}));
            exportPNGFigure(gcf, [sDat.saveDir filesep 'psth_' sDat.movementSetNames{setIdx} filesep 'legend']);
        end
end