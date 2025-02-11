function WriteExcelSheetMac(SegmentedData,~,saveDir,AddID,varargin)

lowb_labels = {};
highb_labels = {};

if mod(numel(varargin), 2) ~= 0
    error('Arguments must be provided in key-value pairs.');
end

for i = 1:2:numel(varargin)
    key = varargin{i};
    value = varargin{i+1};

    switch key
        case 'LowB'
            lowb_labels = value;
        case 'HighB'
            highb_labels = value;
        otherwise
            error('Unknown parameter: %s', key);
    end
end

sz = [0 22];
varTypes = {'string','string','string','string', ...
    'double','double','double','double','double','double','double','double','double','double', ...
    'double','double','double','double','double','double','double','double'};
varNames = {'Phase','Slice','lowB','highB', ...
    'MD','MDstd','FA','FAstd','AD','ADstd','RD','RDstd','HAd','HAdstd', ...
    'HAg','HAgstd','absE2A','absE2Astd','TRA','TRAstd','SA','SAstd'};
T_summ = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
writetable(T_summ,fullfile(saveDir,[AddID '.xlsx']),'Sheet','Summary'); % write initial empty table that will updated at the end

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

                varNames = {'MD','MDstd','FA','FAstd','AD','ADstd','RD','RDstd','HAd','HAdstd','HAg','HAgstd','absE2A','absE2Astd','TRA','TRAstd','SA','SAstd'};
                rowNames = {'A','AS','IS','I','IL','AL','mean'};
                if strcmp(slicelocation{j},'Apex')
                    rowNames = {'A','S','I','L','mean'};
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
                meanAD = SegSlice.means.AD.(lowb{lb}).(highb{hb})';
                stdAD = SegSlice.stds.AD.(lowb{lb}).(highb{hb})';
                meanRD = SegSlice.means.RD.(lowb{lb}).(highb{hb})';
                stdRD = SegSlice.stds.RD.(lowb{lb}).(highb{hb})';
               
                T = table(meanADC,stdADC,meanFA,stdFA,meanAD,stdAD,meanRD,stdRD,meanHAd,stdHAd, ...
                    meanHAg,stdHAg,meanabsE2A,stdabsE2A,meanTA,stdTA,meanSA,stdSA, ...
                    'VariableNames',varNames,'RowNames',rowNames);

                writetable(T,fullfile(saveDir,[AddID '.xlsx']),'Sheet',[lowb{lb} '_' highb{hb} '_' slicelocation{j} '_' cardiacphases{i}(1:3)],'WriteRowNames',true);

                T_summ = [T_summ; table(cardiacphases(i),slicelocation(j),lowb(lb),highb(hb), ...
                    meanADC(end),stdADC(end),meanFA(end),stdFA(end),meanAD(end),stdAD(end),meanRD(end),stdRD(end),meanHAd(end),stdHAd(end), ...
                    meanHAg(end),stdHAg(end),meanabsE2A(end),stdabsE2A(end),meanTA(end),stdTA(end),meanSA(end),stdSA(end), ...
                    'VariableNames', T_summ.Properties.VariableNames)];

            end
        end
    end
end

writetable(T_summ,fullfile(saveDir,[AddID '.xlsx']),'Sheet','Summary');




        