function WriteExcelSheetMac(SegmentedData,~,saveDir,PatID,lowb_labels,highb_labels)

cardiacphases = fieldnames(SegmentedData);

for i=1:length(cardiacphases)
    SegPhase = SegmentedData.(cardiacphases{i});
    slicelocation = fieldnames(SegPhase);
    for j = 1:length(slicelocation)
        SegSlice = SegPhase.(slicelocation{j}).SegmentedData;
        
        if isempty(SegSlice)
            continue
        end
        
        lowb = fieldnames(SegSlice.means.MD);
        for lb=1:length(lowb)
            if ~isempty(lowb_labels)
                if ~any(strcmp(lowb{lb},lowb_labels))
                    continue
                end
            end
            highb = fieldnames(SegSlice.means.MD.(lowb{lb}));
            for hb=1:length(highb)
                if ~isempty(highb_labels)
                    if ~any(strcmp(highb{hb},highb_labels))
                        continue
                    end
                end

                meanADC = SegSlice.means.MD.(lowb{lb}).(highb{hb})';
                stdADC = SegSlice.stds.MD.(lowb{lb}).(highb{hb})';
                meanFA = SegSlice.means.FA.(lowb{lb}).(highb{hb})';
                stdFA = SegSlice.stds.FA.(lowb{lb}).(highb{hb})';
                meanSA = SegSlice.means.SA.(lowb{lb}).(highb{hb})';
                stdSA = SegSlice.stds.SA.(lowb{lb}).(highb{hb})';
                meanabsE2A = SegSlice.means.absE2A.(lowb{lb}).(highb{hb})';
                stdabsE2A = SegSlice.stds.absE2A.(lowb{lb}).(highb{hb})';
                meanTA = SegSlice.means.TRA.(lowb{lb}).(highb{hb})';
                stdTA = SegSlice.stds.TRA.(lowb{lb}).(highb{hb})';
                meanHAd = SegSlice.means.HAd.(lowb{lb}).(highb{hb})';
                stdHAd = SegSlice.stds.HAd.(lowb{lb}).(highb{hb})';
                meanHAg = SegSlice.means.HAg.(lowb{lb}).(highb{hb})';
                stdHAg = SegSlice.stds.HAg.(lowb{lb}).(highb{hb})';
               
                T = table(meanADC,stdADC,meanFA,stdFA,meanSA,stdSA,meanabsE2A,stdabsE2A,...
                    meanTA,stdTA,meanHAd,stdHAd,meanHAg,stdHAg);
                writetable(T,fullfile(saveDir,[PatID '.xlsx']),'Sheet',[lowb{lb} '_' highb{hb} '_' slicelocation{j} '_' cardiacphases{i}(1:3)]);

            end
        end
    end
end




        