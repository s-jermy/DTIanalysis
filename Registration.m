function [dicom2,nfo2,trace] = Registration(dicom,nfo,contours,doAff)
% in:
% dicom - struct containing diffusion images
% nfo - struct containing info about dicom images
% contours - struct containting contours
% doAff - affine or simple registration - t/f
% 
% out:
% dicom2 - struct containing diffusion images with registered images
% nfo2 - struct containing info about dicom images
% trace - struct containing average image for each b-value
% 
% description:
% perform affine or simple registration on the DW images

dicom2 = dicom;
nfo2 = nfo;
trace = {};

%%
cardiacphases = fieldnames(dicom);

for i = 1:length(cardiacphases)
    slicelocation = fieldnames(dicom.(cardiacphases{i}));
    for j = 1:length(slicelocation)
        SliceData = dicom.(cardiacphases{i}).(slicelocation{j}).SliceData;
        SliceInfo = nfo{j}.SliceInfo;

        TEMPtrace = {};

        rec = contours.rec{j};
        B_values = arrayfun(@(x) x.B_value,SliceInfo);
        [uBVal,uBV1,uBV2] = unique(B_values);
        idx = uBVal==50;
        if ~any(idx)
            idx = uBVal==0|uBVal==15;
            if ~any(idx)
                idx = 1;
            end
        end
    
        warning('off','all');
    
        %% Perform the registration on only a small area of the image
        imrangex = rec(1,1):rec(3,1);
        imrangey = rec(1,2):rec(3,2);
    
        if doAff
            regTo = find(idx);
            RegData = AffineReg(SliceData,imrangex,imrangey,B_values,regTo(1));
        else
            regTo = uBV1(idx);
            % regTo = find(cat(1,SliceData(:).contoursDefined)); %haven't defined any contours so...
            if isfield(nfo{j},'RegisterInMatlab')
                regTo = nfo{j}.RegisterInMatlab; %I haven't actually done anything with this field, could be used to override the above if there is a specific image you wish to use
            end
            RegData = SimpleReg(SliceData,imrangex,imrangey,regTo(1));
        end
    
        for k=1:length(uBVal)
            regInd = find(uBV2 == k)';
            TEMPtrace{k} = mean(cat(3,RegData(regInd).regImage),3); %average the images to try improve SNR
        end
    
        warning('on','all');
    
        dicom2.(cardiacphases{i}).(slicelocation{j}).SliceData = RegData;
        nfo2{j}.registrationComplete = 1;
        trace{j} = TEMPtrace;
    end
end

end

function reg_dicom = AffineReg(slice_dicom,x_range,y_range,b_vals,reg_b)
% in:
% slice_dicom - structure containing diffusion images
% x_range/y_range - range to constrain registration
% b_vals - list of unique b-values, so each can be registered separately
%           first
% reg_b - Index of b-value to use as ground-truth for registration
% 
% out:
% reg_dicom - structure containing registered diffusion images
% 
% description:
% affine registration sub function

if isempty(slice_dicom)
    reg_dicom = struct('image',{},'phaseimage',{},'transform',{},'regImage',{},'regPhase',{}); %empty struct
    return
end

h = waitbar(0,'Performing initial registration...');

trans = {};

%% Set registration parameters
[opt,met] = imregconfig('multimodal');
opt.MaximumIterations = 300; %increase number of iterations, allowing more time to converge
opt.InitialRadius = opt.InitialRadius / 10; %reduce initial radius size

%% Find image with the highest average signal intensity
[uBVal,uBV1,uBV2] = unique(b_vals);
regInd = find(uBV2 == reg_b)'; % find b50 images, change to choose different b-value to register to
fixed = 0;
for j = regInd
    if mean(fixed,'all')<mean(slice_dicom(j).image(y_range,x_range),'all')
        fixed = slice_dicom(j).image(y_range,x_range);
    end
end
Rfixed = imref2d(size(fixed));

%% Fixed b-value image registration 
for j = 1:numel(regInd)
    moving = slice_dicom(regInd(j)).image(y_range,x_range);

    tforminit = imregtform(moving,fixed,'similarity',opt,met); %start with a rigid transformation to get us close
    trans{regInd(j)} = imregtform(moving,fixed,'affine',opt,met,'InitialTransformation',tforminit); %then use that as an initial transform, allowing a good affine transform to be found more easily
    
    slice_dicom(regInd(j)).transform = trans{regInd(j)};

    if (isfield(slice_dicom(regInd(j)),'phaseimage'))
        movingPhase = slice_dicom(regInd(j)).phaseimage(y_range,x_range);
        movingComplex = moving.*exp(1i*movingPhase);
    
        tempRegIm = imwarp(movingComplex,trans{regInd(j)},'OutputView',Rfixed);
        slice_dicom(regInd(j)).regImage = abs(tempRegIm);
        slice_dicom(regInd(j)).regPhase = angle(tempRegIm);
    else
        slice_dicom(regInd(j)).regImage  = imwarp(moving,trans{regInd(j)},'OutputView',Rfixed);
    end
    
    waitbar(j/numel(slice_dicom),h);
end
imAver = mean(cat(3,slice_dicom(regInd).regImage),3); %average the images to try improve SNR

%% Register other b-values
%%get rid of the b value we have already registered
% uBVal(reg_b) = [];
uBV1(reg_b) = [];

complete = j; %just for waitbar

%% Find image with the highest average signal intensity
for k = uBV1'
    waitbar(complete/numel(slice_dicom),h,sprintf('Performing registration on b%d...',uBVal(uBV2(k))));
    
    regInd = find(uBV2 == uBV2(k))';
    fixed = 0;
    for j = regInd
        if mean(fixed,'all')<mean(slice_dicom(j).image(y_range,x_range),'all')
            fixed = slice_dicom(j).image(y_range,x_range);
        end
    end
    Rfixed = imref2d(size(fixed));

    %% Get an intermediate registration for all images within a b-value
    for j = 1:numel(regInd)
        moving = slice_dicom(regInd(j)).image(y_range,x_range);

        tforminit = imregtform(moving,fixed,'similarity',opt,met); %rigid transform
        tform{j} = imregtform(moving,fixed,'affine',opt,met,'InitialTransformation',tforminit); %affine transform with rigid as initial
        
        if (isfield(slice_dicom(regInd(j)),'phaseimage'))
            movingPhase = slice_dicom(regInd(j)).phaseimage(y_range,x_range);
            movingComplex = moving.*exp(1i*movingPhase);
            
            tempRegIm = imwarp(movingComplex,tform{j},'OutputView',Rfixed);
            bInter(:,:,j) = abs(tempRegIm); %just take the mag
        else
            bInter(:,:,j)  = imwarp(moving,tform{j},'OutputView',Rfixed);
        end
        
        waitbar((complete+j/2)/numel(slice_dicom),h);
    end
    bAver = mean(bInter,3); %average the images to try improve SNR, especially for the high b-values (dropout might be a problem)

    % Then register the intermediate to the previously defined registered and averaged images
    moving = bAver;
    fixed = imAver;
    Rfixed = imref2d(size(fixed));
    tforminit = imregtform(moving,fixed,'similarity',opt,met); %rigid transform
    tformaver = imregtform(moving,fixed,'affine',opt,met,'InitialTransformation',tforminit); %affine transform with rigid as initial

    % Finally use the intermediate and average transforms to get the final transform for each image
    complete = complete+j/2; %just for waitbar
    waitbar(complete/numel(slice_dicom),h,sprintf('Performing final registration on b%d...',uBVal(uBV2(k))));
    
    for j = 1:numel(regInd)
        moving = slice_dicom(regInd(j)).image(y_range,x_range);

        trans{regInd(j)} = affine2d(tform{j}.T * tformaver.T); %the final transform is found by multiplying the intermediate and the average transforms
        slice_dicom(regInd(j)).transform = trans{regInd(j)};
        
        if (isfield(slice_dicom(regInd(j)),'phaseimage'))
            movingPhase = slice_dicom(regInd(j)).phaseimage(y_range,x_range);
            movingComplex = moving.*exp(1i*movingPhase);
            
            tempRegIm = imwarp(movingComplex,trans{regInd(j)},'OutputView',Rfixed);
            slice_dicom(regInd(j)).regImage = abs(tempRegIm);
            slice_dicom(regInd(j)).regPhase = angle(tempRegIm);
        else
            slice_dicom(regInd(j)).regImage  = imwarp(moving,trans{regInd(j)},'OutputView',Rfixed);
        end
        
        waitbar((complete+j/2)/numel(slice_dicom),h);
    end
    clear tform bInter
    
    complete = complete+j/2; %just for waitbar
end
close(h)

reg_dicom = slice_dicom;

end

function reg_dicom = SimpleReg(slice_dicom,x_range,y_range,reg_to)
% in:
% slice_dicom - structure containing diffusion images
% x_range/y_range - range to constrain registration
% reg_to - Index of image to use as ground-truth for registration
% 
% out:
% reg_dicom - structure containing registered diffusion images
% 
% description:
% simple registration sub function

if isempty(slice_dicom)
    reg_dicom = struct('image',{},'phaseimage',{},'transform',{},'regImage',{},'regPhase',{}); %empty struct
    return
end

fixed = slice_dicom(reg_to).image(y_range,x_range);

h = waitbar(0,'Performing simple registration...');

for j=1:length(slice_dicom)
    moving = slice_dicom(j).image(y_range,x_range);
    
    %% Set registration parameters
    if j == reg_to
        regParams = [0 0 0 0];
    else
        regParams = dftregistration(fft2(fixed),fft2(moving),100);
    end

    %% crop images and register
    if (isfield(slice_dicom(j),'phaseimage'))
        movingPhase = slice_dicom(j).phaseimage(y_range,x_range);
        movingComplex = moving.*exp(1i*movingPhase);
        
        tempRegIm = emt_imshift(movingComplex,-regParams(4),-regParams(3));
        slice_dicom(j).regImage = abs(tempRegIm);
        slice_dicom(j).regPhase = angle(tempRegIm);
    else
        slice_dicom(j).regImage  = emt_imshift(moving,-regParams(4),-regParams(3));
    end
    
    waitbar(j/length(slice_dicom),h);
end
close(h);

reg_dicom = slice_dicom;

end