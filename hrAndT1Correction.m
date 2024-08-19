function [dicom2,nfo2] = hrAndT1Correction(dicom,nfo)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% 
% out:
% dicom2 - structure containing diffusion images with t1 corrected images
% nfo2 - structure containing info about dicom images with hr corrected
%           b-values
% 
% description:
% hr correct the b-values and t1 correct the images

dicom2 = [];
nfo2 = nfo;
cardiacphases = fieldnames(dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        SliceData = dicom.(cardiacphases{i}).(slicelocation{j}).SliceData;
        SliceInfo = nfo{j}.SliceInfo;

        MagneticFieldStrength = nfo{j}.MagneticFieldStrength;
        if MagneticFieldStrength == 1.5
            T1Corr = 1030; 
        elseif MagneticFieldStrength > 1.5
            T1Corr = 1471; % 1471ms T1 of myocardium at 3T https://onlinelibrary.wiley.com/doi/full/10.1002/mrm.20605
        else
            T1Corr = [];
        end

        bVal = arrayfun(@(x) x.B_value,SliceInfo);
        for k=1:length(bVal)
            SliceInfo(k).B_value_uncorr = bVal(k);

            %% correct b-value for heart rate for STE data
            % EMT use nominal interval because it's always there
            % if we have se data with TE < 30ms we're in trouble here
            if nfo{1}.TE < 30
                    bValcorr = bVal(k)*SliceInfo(k).NominalInterval/1000;
                    SliceInfo(k).B_value = bValcorr;                
            end
%             if (isfield(SliceInfo(k),'ImageComments'))
% 
%                 tok = regexp(SliceInfo(k).ImageComments,'R-R ([0-9]+)ms','tokens');
%                 if ~isempty(tok)
%                     hr = str2double(cell2mat(tok{1,1}))/1000;
%                     bValcorr = bVal(k)*hr;
%                     SliceInfo(k).B_value = bValcorr;
%                 end
%             end
        end
    
        %% apply T1 correction for SE data only (this is only convention EMT)
        if nfo{j}.TE > 30
            NominalIntervals = arrayfun(@(x) x.NominalInterval,SliceInfo);
            regImage = cat(3,SliceData(:).regImage);
            if min(NominalIntervals)>0 && ~isempty(T1Corr)
                warning('applying T1 correction to registered images');
                corrfact = 1./(1-exp(-NominalIntervals./T1Corr)); 
                corrfact = permute(corrfact,[3 1 2]);
                regImage = regImage.*repmat(corrfact,size(regImage,1),size(regImage,2));

                for k=1:size(regImage,3)
                    SliceData(k).regImage_uncorr = SliceData(k).regImage;
                    SliceData(k).regImage = regImage(:,:,k);
                end
            else
                warning('!! not applying T1 correction to registered images !!');
            end
        end
    
        try
            SliceData = rmfield(SliceData, {'image','phaseimage'});
        catch
            SliceData = rmfield(SliceData, {'image'});
        end
        dicom2.(cardiacphases{i}).(slicelocation{j}).SliceData = SliceData;
        nfo2{j}.SliceInfo = SliceInfo;
        nfo2{j} = rmfield(nfo2{j},'Info');
    end
end

end