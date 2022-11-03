function SaveFigures(figures,saveDir,additionalTag)

hf = figures.hfig;
height = 700;
width = height*2;

for i=1:length(hf)
%% save b-value figures
    h = waitbar(0,'Saving figures...');
    
    for j=1:length(hf{i})
        figure(hf{i}{j});
        op = hf{i}{j}.OuterPosition; %sj
        hf{i}{j}.OuterPosition = [0 0 width height]; %sj - change to standard size
        warning('off','MATLAB:MKDIR:DirectoryExists');
        mkdir(fullfile(saveDir,additionalTag));
        warning('on','MATLAB:MKDIR:DirectoryExists');
        export_fig(fullfile(saveDir,additionalTag,...
            [sprintf('%d_%d',i,j) '_imageSelection.png']),...
            '-png', '-transparent', '-r100' );
        hf{i}{j}.OuterPosition = op; %sj - reset back to original
        
        waitbar(j/length(hf{i}),h);
    end
    close(h);
end

end