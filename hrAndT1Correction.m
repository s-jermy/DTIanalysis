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

        bVal = arrayfun(@(x) x.B_value,SliceInfo);
        for k=1:length(bVal)
            SliceInfo(k).B_value_uncorr = bVal(k);

            %% correct b-value for heart rate
            if (isfield(SliceInfo(k),'ImageComments'))

                tok = regexp(SliceInfo(k).ImageComments,'R-R ([0-9]+)ms','tokens');
                if ~isempty(tok)
                    hr = str2double(cell2mat(tok{1,1}))/1000;
                    bValcorr = bVal(k)*hr;
                    SliceInfo(k).B_value = bValcorr;
                end
            end
        end
    
        %% apply T1 correction
        NominalIntervals = arrayfun(@(x) x.NominalInterval,SliceInfo);
        regImage = cat(3,SliceData(:).regImage);
        if (min(NominalIntervals)>0)
            warning('applying T1 correction to registered images');
            corrfact = 1./(1-exp(-NominalIntervals./1471)); %sj - where does the 1471 come from?
            corrfact = permute(corrfact,[3 1 2]);
            regImage = regImage.*repmat(corrfact,size(regImage,1),size(regImage,2));

            for k=1:size(regImage,3)
                SliceData(k).regImage_uncorr = SliceData(k).regImage;
                SliceData(k).regImage = regImage(:,:,k);
            end
        else
            warning('!! not applying T1 correction to registered images !!');
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