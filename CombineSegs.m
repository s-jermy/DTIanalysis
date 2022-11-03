function seg_dicom2 = CombineSegs(seg_dicom,ha_dicom)

seg_dicom2 = seg_dicom;

cardiacphases = fieldnames(seg_dicom);
for i=1:length(cardiacphases)
    slicelocation = fieldnames(seg_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        seg_struct = seg_dicom.(cardiacphases{i}).(slicelocation{j}).SegmentedData;
        ha_struct = ha_dicom.(cardiacphases{i}).(slicelocation{j}).SegmentedData;
        
        if isempty(seg_struct)||isempty(ha_struct)
            seg_dicom2.(cardiacphases{i}).(slicelocation{j}).SegmentedData = [];
            continue
        end
        
        means = seg_struct.means;
        stds = seg_struct.stds;
        
        means2 = ha_struct.means;
        stds2 = ha_struct.stds;
        
        mergestructs = @(x,y) cell2struct([struct2cell(x);struct2cell(y)],[fieldnames(x);fieldnames(y)]);
        means = mergestructs(means,means2);
        stds = mergestructs(stds,stds2);
        
        seg_dicom2.(cardiacphases{i}).(slicelocation{j}).SegmentedData.means = means;
        seg_dicom2.(cardiacphases{i}).(slicelocation{j}).SegmentedData.stds = stds;
    end
end

end
