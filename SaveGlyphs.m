function SaveGlyphs(figures,saveDir)

hf = figures.hfig;

for i=1:length(hf) %cardiac phases and slice locations
    for j=1:length(hf{i}) %glyph maps
        figure(hf{i}{j}); %bring figure into focus

        f = hf{i}{j}.Tag; %folder name
        n = hf{i}{j}.Name; %file name
        ud = hf{i}{j}.UserData; %position information
    
        targetx = round(ud(:,1));
        targety = round(ud(:,2));
    
        op = hf{i}{j}.OuterPosition; %sj - store old figure position and size
        hf{i}{j}.OuterPosition = [0 0 800 800]; %sj - change to standard size
    
        %move camera to low angle view
        set(gcf().Children,'View',[-12 16])
        set(gcf().Children,'CameraPosition',[-76 633 202])
        set(gcf().Children,'CameraViewAngle',2.3)
    
        fname1 = fullfile(saveDir,f,'glyph');
        warning('off','MATLAB:MKDIR:DirectoryExists');
        mkdir(fname1);
        warning('on','MATLAB:MKDIR:DirectoryExists');
    
        %sj - save a couple different views
        for x = 1:length(targetx)
            set(gcf().Children,'CameraTarget',[targetx(x) targety(3) 0])
            fname = fullfile(fname1,[n '_' int2str(x) '.png']);
            export_fig(fname, '-png', '-transparent', '-r100');
        end
    
        hf{i}{j}.OuterPosition = op; %sj - reset back to original
        % saveas(hf{i}{j},fullfile(saveDir,f,n)); %sj - save the figure as .fig
    end
end

end