function [averaged_dicom,SNR_estimate] = Average(dicom,nfo)
% in:
% dicom - struct containing diffusion images
% nfo - struct containing info about dicom images
% 
% out:
% averaged_dicom - struct with average images
% SNR_estimate - estimated SNR map
% 
% description:
% average images for each unique b-value and gradient direction

averaged_dicom = [];
SNR_estimate = [];

cardiacphases = fieldnames(dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(dicom.(cardiacphases{i}));
    for j = 1:length(slicelocation)
        SliceData = dicom.(cardiacphases{i}).(slicelocation{j}).SliceData;
        SliceInfo = nfo{j}.SliceInfo;
    
        regImage = cat(3,SliceData(:).regImage);
        if isfield(SliceData,'regPhase') %combine mag and phase images if phase available
            regPhase = cat(3,SliceData(:).regPhase);
            regImage = regImage.*exp(1i.*regPhase);
        end
    
        DiffDirVecs = cat(1,SliceInfo(:).DiffDirVec); %gradient directions
        [uDiffDirs,~,uDD2] = uniquetol(DiffDirVecs,1e-4,'ByRows',true); %find gradients that are within a 1e-4 tolerance of each other
        TMPDiffDirs = uDiffDirs(uDD2,:); %sz = size(TMPDiffDirs); %reconstruct array, treating the values that are within tolerance as equal
%         DiffDirVecs = mat2cell(tmp,ones(sz(1),1))';
        [uDiffDirs,~,uDD2] = unique(TMPDiffDirs,'rows','stable');
        sz = size(uDiffDirs,1);
        % this is logic to deal with inverted (and within tolerance) diffusion directions which are equivalent
        if sz > 1 
           for jj=1:sz
                for kk=jj+1:sz
                    if abs(uDiffDirs(kk,:)+uDiffDirs(jj,:))<1e-4
                        uDD2(uDD2 == kk) = jj;
                        break;
                    end
                end
           end
        end
        DiffDirVecs = uDiffDirs(uDD2,:);
        
        bValUncorr = arrayfun(@(x) x.B_value_uncorr,SliceInfo); %uncorrected b-vallues
        bVal = arrayfun(@(x) x.B_value,SliceInfo); %corrected b-vallues
        
        TMPbMatrix = repmat(bValUncorr',[1 3]).*DiffDirVecs;
        [uBMat,~,uBM2]=uniquetol(TMPbMatrix,1e-6,'ByRows',true); %find unique values within a tolerance of 1e-6
        TMPbMatrix = uBMat(uBM2,:); %reconstruct array, treating the values that are within tolerance as equal.
        [uBMat,uBM1,uBM2]=unique(TMPbMatrix,'rows','stable');
    %     [~,order] = sort(bValUncorr);
    
    %don't try sorting, this borked the whole thing - past steve XOXO
%         [TMPbValUncorr,ind] = sort(bValUncorr(uBM1));
        TMPbValUncorr = bValUncorr(uBM1);
        % TMPbVal = bVal(uBM1); %TMPbVal = TMPbVal(ind);
        for cBM = 1:length(uBM1) % EMT because we want to take into account all instances of a b-value
            TMPbVal(cBM) = mean(bVal(uBM2==cBM));
        end
        TMPdir = DiffDirVecs(uBM1,:); %TMPdir = TMPdir(ind,:);
    
        refbVal = min(TMPbValUncorr,[],'all');
        bValInd = bValUncorr == refbVal;
        [~,dirmain] = intersect(uBMat,unique(TMPbMatrix(bValInd,:),'rows'),'rows');
    
        TMPRegImage = {};
        if (length(dirmain) > 1)
            if length(uBM1)>1
                dirmain = dirmain(1);
                regInd = uBM2==dirmain;
                TMPRegImage{dirmain} = regImage(:,:,regInd);
            else
                dirmain = 0;
            end
        elseif (length(dirmain) == 1)
            regInd = uBM2==dirmain;
            TMPRegImage{dirmain} = regImage(:,:,regInd);
        end
        for k=1:length(uBM1)
            if k~=dirmain
                regInd = uBM2==k;
                if (sum(bValUncorr(uBM1)==bValUncorr(uBM1(k)))>=6)
                    TMPRegImage{k} = regImage(:,:,regInd);
                else
                    warning('skipping b=%d s/mm^2',bValUncorr(uBM1(k)));
                end
            end
        end        
    
        if ~isreal(regImage)
            [TMPav,~] = ComplexAverage(TMPRegImage);
        else
            TMPav = SimpleAverage(TMPRegImage);
        end
        
        if ~isempty(TMPav)
            for k=1:size(TMPav,3)
                averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData(k).image = TMPav(:,:,k);
                averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData(k).B_value_uncorr = TMPbValUncorr(k);
                averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData(k).B_value = TMPbVal(k);
                averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData(k).dir = TMPdir(k,:);
        %         averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData(k).bMatrix = uBMat(k,:);
            end
        else
            averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData(k) = struct('image',{},'B_value_uncorr',{},'B_value',{},'dir',{});
        end
    
        %% estimate SNR
        if dirmain>0
            SNR_estimate = mean(abs(regImage(:,:,bValInd)),3)./std(abs(regImage(:,:,bValInd)),0,3);
            SNR_estimate(isinf(SNR_estimate)) = 0;
        else
            SNR_estimate = zeros(size(regImage(:,:,1)));
        end
    end
end

end

function [comp_av,simp_av] = ComplexAverage(dcm)
% in:
% dcm - struct containing diffusion images
% 
% out:
% comp_av - struct containing complex averaged diffusion images
% simp_av - struct containing simple averaged diffusion images
% 
% description:
% complex averaging sub function

comp_av = [];

h = waitbar(0,'Performing complex averaging...');

for i=1:length(dcm)
    imsize = size(dcm{i});
    pyra = pyramidfilter(imsize(1),imsize(2),1); %10.1002/nbm.3500 and 10.1002/mrm.10014
%     cone = conefilter(imsize(1),imsize(2),1);
    for j=1:size(dcm{i},3)
       im = dcm{i}(:,:,j);
       filtered = ifft2(ifftshift(pyra).*fft2(im));
       orig_phase = (angle(im));
       filt_phase = (angle(filtered));
       corrected(:,:,j) = abs(im).*exp(1i.*(wrapToPi(orig_phase-filt_phase))); %subtract low-res phase from original
    end
    comp_av(:,:,i) = abs(mean(corrected,3));
    corrected = [];

    waitbar(i/length(dcm),h);
end

close(h);

simp_av = SimpleAverage(dcm);
end

function av = SimpleAverage(dcm)
% in:
% dcm - struct containing diffusion images
% 
% out:
% av - struct containing averaged diffusion images
% 
% description:
% simple averaging sub function

av = [];

h = waitbar(0,'Performing simple averaging...');

for i=1:length(dcm)
    av(:,:,i) = mean(abs(dcm{i}),3);
   
    waitbar(i/length(dcm),h);
end

close(h);

end

%{
function cone = conefilter(ydim,xdim,width_factor)

x2 = round(xdim/width_factor); y2 = round(ydim/width_factor);

[X,Y] = meshgrid(1:xdim,1:ydim);

X = X - xdim/2;
Y = Y - ydim/2;

radius = max(x2,y2)/2;

cone = 1-(X.^2+Y.^2)./radius.^2;
cone(cone<0) = 0;

end
%}

function pyra = pyramidfilter(ydim,xdim,width_factor)
% in:
% ydim - y dimension length
% xdim - x dimension length
% 
% out:
% pyra - pyramid filter kernel
% 
% description:
% see 10.1002/nbm.3500 and 10.1002/mrm.10014

x2 = round(xdim/width_factor); y2 = round(ydim/width_factor);

[X,Y] = meshgrid(1:xdim,1:ydim);

X = X - round(xdim/2);
Y = Y - round(ydim/2);

xpyra = 1 - X.^2./round(x2/2).^2; xpyra(xpyra<0)=0;
ypyra = 1 - Y.^2./round(y2/2).^2; ypyra(ypyra<0)=0;
pyra = xpyra.*ypyra;

end