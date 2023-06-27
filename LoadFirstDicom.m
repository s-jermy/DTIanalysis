function [dcmInfo] = LoadFirstDicom(dirlisting)
% in:
% dirlisting - list of diffusion images files
%
% out:
% dcmInfo - first diffusion image metadata
% 
% description:
% load first valid dicom file from the chosen directory

dcmInfo = [];
first = false; j=1;

notdir = arrayfun(@(x) ~x.isdir,dirlisting);
dirlisting = dirlisting(notdir); %remove folders

[~,~,ext] = arrayfun(@(x) fileparts(x.name),dirlisting,'UniformOutput',false);
valid = cellfun(@(x) all(x=='.ima'|x=='.dcm'),ext);
dirlisting = dirlisting(valid); %remove non-dicom files

while (~first)
    try
        dcmInfo = dicominfo(fullfile(dirlisting(j).folder,dirlisting(j).name));
        first = true;
    catch
        fprintf('%s is not a dicom file\n',dirlisting(j).name); %hopefully this shouldn't happen
        j = j+1; %try the next file
        continue
    end
end

end