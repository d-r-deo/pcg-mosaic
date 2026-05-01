function exportPNGFigure(fHandle, fileName)
    saveas(fHandle,[fileName '.fig'],'fig');
    saveas(fHandle,[fileName '.svg'],'svg');
    saveas(fHandle, [fileName '.png']);

end
