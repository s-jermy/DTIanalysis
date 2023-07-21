function SaveGlyphs(figures,saveDir)

hf = figures.hfig;
% height = 700;
% width = height*2;

for i=1:length(hf)
    f = hf{i}.Tag;
    n = hf{i}.Name;

    saveas(hf{i},fullfile(saveDir,f,n));
end

end