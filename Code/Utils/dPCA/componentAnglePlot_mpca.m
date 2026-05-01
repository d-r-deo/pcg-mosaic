function componentAnglePlot_mpca( W )
  
    figure('Position',[379   855   312   243]);
    
    b = W'*W;
    [~, psp] = corr(W, 'type', 'Kendall');
    
    imagesc(b,[-1 1]);
    
    cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
    colormap(cMap);

    xlabel('Component')
    ylabel('Component')
    set(gca,'FontSize',16,'LineWidth',2);

    cb = colorbar('FontSize',16,'LineWidth',2);

    hold on
    [i,j] = ind2sub(size(triu(b,1)), ...
        find(abs(triu(b,1)) > 3.3/sqrt(size(W,1)) & psp<0.001)); % & abs(csp)>0.02));
    plot(j,i,'k*')
    
    text(0.57,0.90,'Dot Product\newlineBetween Axes','FontSize',12,'Units','Normalized');
end

