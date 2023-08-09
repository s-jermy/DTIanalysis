function [nfo2,AHAslicelocations,figures] = RejectImages(dicom,nfo,contours)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% contours - structure containting contours
% 
% out:
% nfo2 - structure containing info about dicom images
% AHAslicelocations - slice locations labels for categorisation
% figures - reject image figures to be saved
% 
% description:
% select images with poor image quality to remove from the rest of the 
% analysis

nfo2 = nfo;
TMPnfo = {};
figures = struct;
slicelocations = cellfun(@(x) x.SliceLocation,nfo,'UniformOutput',false);
cardiacphases = cellfun(@(x) x.CardiacPhase,nfo,'UniformOutput',false);

returnZeros = @(errstr,x) [0; 0; 0];
doNothing = @(src,~,i,j) [];
Labels = {'Base', 'Mid', 'Apex', 'Systole', 'Diastole', 'nonAHA'};
bVsum = 0;

for i=1:length(dicom)
    ubVals = unique(arrayfun(@(x) x.B_value,nfo{i}.Info));
    rec{i} = contours.rec{i};
    imrangex = rec{i}(1,1):rec{i}(3,1);
    imrangey = rec{i}(1,2):rec{i}(3,2);
    imrangex = imrangex(imrangex>0);
    imrangey = imrangey(imrangey>0);
    
    % extract modal series name
    SDs = arrayfun(@(x) x.SeriesDescription,nfo{i}.Info,'UniformOutput',false);
    [SDu,SD1,~] = unique(SDs);
    for j=1:length(SD1)
        SDl(j) = sum(strcmp(SDs,SDu{j}));
    end
    [~,modal] = max(SDl);
    SeriesDescription{i} = SDu{modal};
    nfo2{i}.SeriesDescription = SeriesDescription{i};
    clear SDu SD1 SDl SDs
    
    %% Fill figure array with DW images
    h = waitbar(0,'Filling figure arrays...');
    for bV=1:length(ubVals)
        bVind = arrayfun(@(z) max(z.B_value==ubVals(bV)),nfo{i}.Info);
        dicom2{i}{bV} = dicom{i}(bVind);
        TMPnfo{i}{bV} = nfo{i}.Info(bVind);
        
        % now sort the images by diffusion direction and b-value
        diffDirsCell{i}{bV} = arrayfun(@(x) x.DiffDirVec,TMPnfo{i}{bV},'UniformOutput',false,'ErrorHandler',returnZeros);
        [uDiffDirs,~,uDD2] = uniquetol(cat(1,diffDirsCell{i}{bV}{:}),1e-4,'ByRows',true); %find gradients that are within a tolerance of each other
        tmp = uDiffDirs(uDD2,:); sz = size(tmp);
        diffDirsCell{i}{bV} = mat2cell(tmp,ones(sz(1),1))';
        [uDiffDirs,~,uDD2] = unique(cat(1,diffDirsCell{i}{bV}{:}),'rows','stable');
        sz = size(uDiffDirs,1);
        % this is logic to deal with inverted (and within tolerance) diffusion directions which are equivalent
        if sz > 1 
           for j=1:sz
                for k=j+1:sz
                    if abs(uDiffDirs(k,:)+uDiffDirs(j,:))<1e-4
                        uDD2(uDD2 == k) = j;
                        break;
                    end
                end
           end
        end
        tmp = uDiffDirs(uDD2,:);
        [uDiffDirs,~,uDD2] = unique(tmp,'rows','stable');
        sz = size(uDiffDirs,1);
           
        if sz > 16 %sj - this is to deal with 64 dirs being displayed in a long row
            temp = linspace(1,size(uDD2,1),size(uDD2,1));
            uDD2 = mod(temp-1,16)+1;
        end
            
        if sz == 1  %sj - this is to deal with all the b0's being displayed in a long column
            temp = linspace(1,size(uDD2,1),size(uDD2,1));
            uDD2 = mod(temp-1,round(sqrt(size(uDD2,1))))+1;
        end
        
        for j=1:max(uDD2)
            ImsPerDir{i}{bV}(j) = sum(uDD2==j);
        end
        
        hf{i}{bV} = figure(i+bV*15);clf;
        clear temp
        
        %% Fill figure with images with different b-values
        % need some logic here to make sure there's enough room for labels
        % if there aren't many directions
        ha = tight_subplot(max(ImsPerDir{i}{bV})+1,max(max(uDD2),7),0.01,0.01,0.01);
        trackpos = zeros(1,max(max(uDD2),7));
        for j = 1:length(diffDirsCell{i}{bV})
            trackpos(uDD2(j)) = trackpos(uDD2(j))+1;
            subplotindex = uDD2(j)+(trackpos(uDD2(j))-1)*(max(max(uDD2),7));
            ah{i}{bV}{subplotindex} = subplot(ha(subplotindex)); % diffusion dirs columns x no of images per dirn rows; numbered by row, i.e. 1 2 3;4 5 6...

            warning('off','all');
            % window individual images before combining into one - modified
            % imshowpair
%             WC = TMPnfo{i}{bV}(j).WindowCenter;
%             WW = TMPnfo{i}{bV}(j).WindowWidth;
            WC = 62.5; WW = 125;
            low = WC-.5 - (WW-1)/2; high = WC-.5 + (WW-1)/2; % for mag images
            
            mag = single(dicom2{i}{bV}(j).image(imrangey,imrangex));
            mag(mag<=low) = low; mag(mag>high) = high;
            mag = ((mag-(WC-.5))/(WW-1)+.5)*255;
            mag = uint8(mag);
            
            if isfield(dicom2{i}{bV}(j),'phaseimage')
                phase = single(dicom2{i}{bV}(j).phaseimage(imrangey,imrangex));
                phase = (phase + pi) / (2*pi);
                phase = im2uint8(phase);
            else
                phase = [];
            end
            % if you didn't do affine, just use the normal images
            
            if max(ImsPerDir{i}{bV}) >= max(max(uDD2),6)
                TMPim = [mag phase];
            else
                TMPim = [mag;phase];
            end
            
            im{i}{bV}{j} = imshow(TMPim);
            warning('on','all');

            im{i}{bV}{j}.ButtonDownFcn = {@ChangeSelectionStatus,i,j};
            im{i}{bV}{j}.Parent.Visible = 'on';
            im{i}{bV}{j}.Parent.YTick = mean(im{i}{bV}{j}.Parent.YLim);
            im{i}{bV}{j}.Parent.YTickLabel = TMPnfo{i}{bV}(j).SeriesNumber;
            im{i}{bV}{j}.Parent.XTick = [];
%             if (dicom2{i}{bV}(j).contoursDefined)
%                 im{i}{bV}{j}.Parent.LineWidth = 3;
%                 im{i}{bV}{j}.Parent.XColor = 'b';
%                 im{i}{bV}{j}.Parent.YColor = 'b';
%             end
            im{i}{bV}{j}.Tag = TMPnfo{i}{bV}(j).SOPInstanceUID;
        end
        
        %% Add labels to images
        for j = 1:max(max(uDD2),7)
            subplotindex = j + (max(ImsPerDir{i}{bV})*max(max(uDD2),7));
            ah{i}{bV}{subplotindex} = subplot(ha(subplotindex));
            ah{i}{bV}{subplotindex}.Visible = 'off';
            if (bV == 1)
                if (j <= length(Labels))
                    txt{i}{bV}{j} = text(0,0.5,Labels{j},'Color','w');
                    if ((j < 4) || (j == 6))
                        txt{i}{bV}{j}.BackgroundColor = [0 0.5 0];
                    else
                        txt{i}{bV}{j}.BackgroundColor = [0 0 0.7];
                    end
                    txt{i}{bV}{j}.ButtonDownFcn = {@ChangeSelectionStatus,i,0};
                end
            end
            if (j == max(max(uDD2),7))
                txt{i}{bV}{j} = text(0,0.5,'Done','BackgroundColor','r','Color','w');
                txt{i}{bV}{j}.ButtonDownFcn = {@ChangeSelectionStatus,i,bV*20};
            end
        end
        hf{i}{bV}.Name = [SeriesDescription{i} ' ' sprintf('%.1f',TMPnfo{i}{bV}(1).TriggerTime) ' ' sprintf('%.1f',slicelocations{i}) ' ' sprintf('b = %d s/mm^2',ubVals(bV))];
        
        %% Turn off visibility for empty subplots
        mt = find(cellfun(@isempty,ah{i}{bV}));
        for j = mt
            ah{i}{bV}{j} = subplot(ha(j));
            ah{i}{bV}{j}.Visible = 'off';
        end
        
        waitbar(bV/length(ubVals),h);
    end
bVsum = bVsum+i*(sum(1:bV)*20);
close(h);
end
f = msgbox('Finishing up...');

%% How many slice there are, and in what phase
for i=1:length(slicelocations)
    if (isempty(slicelocations{i}))
        SLtoSort(i) = 1e5;
    else
        SLtoSort(i) = slicelocations{i};
    end
end
[OrderedSliceLocations, OSLi] = sort(SLtoSort);
OSLi = OSLi(abs(OrderedSliceLocations)<1e3);
SSLi = OSLi(cellfun(@(x) strcmp(x,'Systole'),{cardiacphases{OSLi}}));
DSLi = OSLi(cellfun(@(x) strcmp(x,'Diastole'),{cardiacphases{OSLi}}));
SLi = {SSLi,DSLi};

% deselect other phase for all these slices
for i=1:length(SSLi)
    ChangeSelectionStatus(txt{SSLi(i)}{1}{5},[],SSLi(i),0); % disable diastole if systole
end
for i=1:length(DSLi)
    ChangeSelectionStatus(txt{DSLi(i)}{1}{4},[],DSLi(i),0); % disable systole if diastole
end

%% select tags that correspond to slice position and phase
for k = 1:2
    if ~(isempty(SLi{k}))
        if (length(SLi{k}) <= 3)
            % most basal slice is lowest abs slice location: deselect mid and apex
            ChangeSelectionStatus(txt{SLi{k}(1)}{1}{2},[],SLi{k}(1),0); % deselect mid
            ChangeSelectionStatus(txt{SLi{k}(1)}{1}{3},[],SLi{k}(1),0); % deselect apex
            ChangeSelectionStatus(txt{SLi{k}(1)}{1}{6},[],SLi{k}(1),0); % deselect nonAHA
            % most apical slice is highest abs slice location: deselect mid and base
            ChangeSelectionStatus(txt{SLi{k}(end)}{1}{2},[],SLi{k}(end),0); % deselect mid
            ChangeSelectionStatus(txt{SLi{k}(end)}{1}{1},[],SLi{k}(end),0); % deselect base
            ChangeSelectionStatus(txt{SLi{k}(end)}{1}{6},[],SLi{k}(end),0); % deselect nonAHA
            if (length(SLi{k}) == 3)
                % if there's only one slice left, it's the mid slice
                ChangeSelectionStatus(txt{SLi{k}(2)}{1}{3},[],SLi{k}(2),0); % deselect apex
                ChangeSelectionStatus(txt{SLi{k}(2)}{1}{1},[],SLi{k}(2),0); % deselect base
                ChangeSelectionStatus(txt{SLi{k}(2)}{1}{6},[],SLi{k}(2),0); % deselect nonAHA
            end
        elseif (length(SLi{k}) > 3)
            % otherwise, scan through for any slices with three contours
            % defined and choose this one (or the most basal one if there's
            % more than one
            for i = 1:length(SLi{k})
                ChangeSelectionStatus(txt{SLi{k}(i)}{1}{3},[],SLi{k}(i),0);	% deselect apex
                ChangeSelectionStatus(txt{SLi{k}(i)}{1}{1},[],SLi{k}(i),0);	% deselect base
                ChangeSelectionStatus(txt{SLi{k}(i)}{1}{2},[],SLi{k}(i),0);	% deselect mid
            end
        end
    end
end

%% wait for user to press done for all figures
close(f);
f = msgbox('Ready');pause(0.5);close(f);

temptxt = [txt{~cellfun(@isempty,txt)}];
while (sum(prod(cell2mat(arrayfun(@(x) x{:}{end}.UserData,temptxt,'UniformOutput',false)'),2)) < bVsum)
    pause(1);
end

%% get labels from figures
errorState = false;
AHAslicelocations = cell(size(dicom));
nonAHA = 0;
for i=1:length(txt)
    if (~isempty(rec{i}))
        if (isempty(txt{i}{1}{4}.UserData))
            cardiacphases{i} = 'Systole';
            if (isempty(txt{i}{1}{5}.UserData))
                errorState = true;
                warning('Slice %s (Fig %d) is labelled both Systole and Diastole',SeriesDescription{i},i);
            end
        else
            if (isempty(txt{i}{1}{5}.UserData))
                cardiacphases{i} = 'Diastole';
            else
                errorState = true;
                warning('Slice %s (Fig %d) is labelled as neither Systole nor Diastole',SeriesDescription{i},i);
            end
        end
        
        if (isempty(txt{i}{1}{1}.UserData))
            AHAslicelocations{i} = 'Base';
        end
        if (isempty(txt{i}{1}{2}.UserData))
            if (~isempty(AHAslicelocations{i}))
                errorState = true;
                warning('Slice %s (Fig %d) is labelled both %s and Mid',SeriesDescription{i},i,AHAslicelocations{i});
            end
            AHAslicelocations{i} = 'Mid';
        end
        if (isempty(txt{i}{1}{3}.UserData))
            if (~isempty(AHAslicelocations{i}))
                errorState = true;
                warning('Slice %s (Fig %d) is labelled both %s and Apex',SeriesDescription{i},i,AHAslicelocations{i});
            end            
            AHAslicelocations{i} = 'Apex';
        end
        while (isempty(AHAslicelocations{i}))
            nonAHA=nonAHA+1;
            if ~(strcmp(AHAslicelocations,['Slice' sprintf('%d',nonAHA)]))
                AHAslicelocations{i} = ['Slice' sprintf('%d',nonAHA)];
            end
        end
    end

    if (errorState)
        error('Issues with slice labels: see warnings above and fix');
    end
end

figures.hfig = hf;
% figures.hsubplot = ah;
figures.himage = im;
% figures.htext = txt;

end

function ChangeSelectionStatus(src,~,i,j)

if (isempty(src.UserData))
    src.UserData = [i j];
    DeSelect(src);
else
    src.UserData = [];
    Select(src);
end

end

function Select(src)

if (strcmp(src.Type,'image'))
    src.AlphaData = 1;
end
if (strcmp(src.Type,'text'))
    src.BackgroundColor = src.BackgroundColor*2;
    src.Color = src.Color*2;
end

end


function DeSelect(src)

if (strcmp(src.Type,'image'))
    src.AlphaData = 0.5;
end
if (strcmp(src.Type,'text'))
    src.BackgroundColor = src.BackgroundColor/2;
    src.Color = src.Color/2;
end

end