function tensor_dicom = CalculateTensor(averaged_dicom)
% in:
% averaged_dicom - struct containing averaged diffusion images
% 
% out:
% tensor_dicom - struct containing tensors,eigenvectors,eigenvalues
% 
% description:
% calculate ans solve diffusion tensors

tensor_dicom = [];

cardiacphases = fieldnames(averaged_dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(averaged_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        AveragedData = averaged_dicom.(cardiacphases{i}).(slicelocation{j}).AveragedData;
%       SliceInfo = nfo{j}.SliceInfo;

        if isempty(AveragedData)
            tensor_dicom.(cardiacphases{i}).(slicelocation{j}) = struct('tensor',{},'eigVector',{},'eigValue',{});
            continue
        end

        h = waitbar(0,'Calculating tensors...');
    
        avImage = cat(3,AveragedData(:).image);
        bValUncorr = cat(1,AveragedData(:).B_value_uncorr);
        bVal = cat(1,AveragedData(:).B_value);
        diffDirVec = cat(1,AveragedData(:).dir);
%       bMatrix = cat(1,AveragedData(:).bMatrix);
    
        [uBVal,~,uBV2] = unique(bValUncorr);
        
        n = length(uBVal);
        count = 0;
        for k=1:(n-1)
            lSignal = avImage(:,:,uBV2==k);
            lDirVec = diffDirVec(uBV2==k,:);
            lBVal = bVal(uBV2==k);
            lBValUncorr = bValUncorr(uBV2==k);
            lBVlabel = sprintf('b%d',lBValUncorr(1));
            for l=(k+1):n
                count = count+1;

                hSignal = avImage(:,:,uBV2==l);
                Signal = cat(3,lSignal,hSignal);
                Signal(Signal==0) = 0.0001; %ln(0) = Inf

                hDirVec = diffDirVec(uBV2==l,:);
                diffDirVec2 = cat(1,lDirVec,hDirVec);

                hBVal = bVal(uBV2==l);
                bVal2 = cat(1,lBVal,hBVal);

                [TMPtensor,~,TMPeigVector,TMPeigValue] = calcBMatrix(Signal,diffDirVec2,bVal2); %10.1002/cmr.a.20050

                hBValUncorr = bValUncorr(uBV2==l);
                hBVlabel = sprintf('b%d',hBValUncorr(1));
                tensor_dicom.(cardiacphases{i}).(slicelocation{j}).tensor.(lBVlabel).(hBVlabel) = TMPtensor;
                tensor_dicom.(cardiacphases{i}).(slicelocation{j}).eigVector.(lBVlabel).(hBVlabel) = TMPeigVector;
                tensor_dicom.(cardiacphases{i}).(slicelocation{j}).eigValue.(lBVlabel).(hBVlabel) = TMPeigValue;

                waitbar(count/(n*(n-1)/2),h)
            end
        end
        close(h);
    end
end

end

function [tensor,lnS0,eigVector,eigValue] = calcBMatrix(signal,dirVector,bVal)
% in:
% signal - low and high b-value images
% dirVector - diffusion direction vectors
% bVal - low and high b-values
% 
% out:
% tensor - pixelwise 3D tensor field
% lnS0 - log b0 image
% eigVector - pixelwise eigenvectors of tensor
% eigValue - pixelwise eigenvalues
% 
% description:
% calculate b-matrix for each pixel

imsize = size(signal);
N_measures = imsize(3);

tensor = zeros(imsize(1),imsize(2),3,3);
lnS0 = zeros(imsize(1:2));
eigVector = zeros(imsize(1),imsize(2),3,3);
eigValue = zeros(imsize(1),imsize(2),3);

bVal = repmat(bVal,[1 3]);
bvDirVec = sqrt(bVal).*dirVector; % B-value direction vectors
lnSignal = log(abs(signal));

bMatrix = zeros(N_measures,7);

%% fill B-matrix
for i=1:N_measures
  bMatrix(i,1) =   -bvDirVec(i,1)*bvDirVec(i,1);
  bMatrix(i,2) =   -bvDirVec(i,2)*bvDirVec(i,2);
  bMatrix(i,3) =   -bvDirVec(i,3)*bvDirVec(i,3);
  bMatrix(i,4) = -2*bvDirVec(i,1)*bvDirVec(i,2);
  bMatrix(i,5) = -2*bvDirVec(i,1)*bvDirVec(i,3);
  bMatrix(i,6) = -2*bvDirVec(i,2)*bvDirVec(i,3);
  bMatrix(i,7) = 1;
end

if rank(bMatrix)<7
    warning('Not a rank 7 tensor, not good') %need to come up with some error check for this
    return
end

%% calculate tensor for each pixel
for row=1:imsize(1)
    for col=1:imsize(2)
        alpha = bMatrix \ squeeze(lnSignal(row,col,:));
        
        %%diagonals
        tensor(row,col,1,1) = alpha(1);
        tensor(row,col,2,2) = alpha(2);
        tensor(row,col,3,3) = alpha(3);
        
        %%off-diagonals
        tensor(row,col,1,2) = alpha(4);
        tensor(row,col,2,1) = alpha(4);
        tensor(row,col,1,3) = alpha(5);
        tensor(row,col,3,1) = alpha(5);
        tensor(row,col,2,3) = alpha(6);
        tensor(row,col,3,2) = alpha(6);
        
        lnS0(row,col) = alpha(7);
        
        [v,d] = eig(squeeze(tensor(row,col,:,:)));
        
        d = diag(d);
        [dsort,evsort] = sort(abs(d),'descend');
        eigValue(row,col,:) = dsort;
        eigVector(row,col,:,:) = v(:,evsort);
    end
end

end