function SaveGlyphs(figures,saveDir)

hf = figures.hfig;
% height = 700;
% width = height*2;

for i=1:length(hf)
    figure(hf{i});
    
    f = hf{i}.Tag;
    n = hf{i}.Name;
    ud = hf{i}.UserData;

    targetx = round(ud(2,1));
    targety = round(ud(3,2));

    view(-12,16);
    campos([-76,-633,202]);
    camtarget([targetx,targety,0]);
    camva(2.3);

    saveas(hf{i},fullfile(saveDir,f,n));
end

end