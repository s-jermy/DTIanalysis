function WriteExcelSheet(Excel,Workbook,SegmentedData,nfo,saveDir,patID,lowb_labels,highb_labels)

% Get a handle to Sheets and select Sheet 1
Sheets = Workbook.Sheets;
% % Add one more sheet for this slice
% lastSheet = get(Sheets, 'Item', Sheets.Count);
% Sheets.Add([],lastSheet); % Add as LAST sheet.

SheetMain = get(Sheets, 'Item', 1);
SheetMain.Activate;

% Name worksheet
sheetMain_name='Summary';
SheetMain.Name=sheetMain_name;

% Temporarily disable screen updates for speed
Excel.Application.ScreenUpdating = false;
cleanup_updating = onCleanup(@() set(Excel.Application,'ScreenUpdating',true));

m = 0;
val = 'dummy';
while (~isempty(val))
    m = m+1;
    val = SheetMain.Range(['A' num2str(m)]).Text;
end

if (m==1)
    SheetMain.Range('A1').Value = 'Phase';
    SheetMain.Range('B1').Value = 'Slice';
    SheetMain.Range('C1').Value = 'lowB';
    SheetMain.Range('D1').Value = 'highB';
    
    metrics = {'MD';'FA';'AD';'RD';'HAd';'HAg';'absE2A';'TRA';'SA'};
    coln = 'D';
    for j=1:length(metrics)
        coln = coln+1;
        SheetMain.Range([char(coln) '1']).Value = metrics{j};
        coln = coln+1;
        SheetMain.Range([char(coln) '1']).Value = [metrics{j} 'std'];
    end
end
m = m+1;

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
                % Add one more sheet for this slice
                lastSheet = get(Sheets, 'Item', Sheets.Count);
                Sheets.Add([],lastSheet); % Add as LAST sheet.

                SheetSlice = get(Sheets, 'Item', Sheets.Count);
                SheetSlice.Activate;

                % Name worksheet
                SheetSlice.Name=[lowb{lb} '_' highb{hb} '_' slicelocation{j} '_' cardiacphases{i}(1:3)];

                % Build
                SheetSlice.Range('A1').Value = sprintf('ID');
                SheetSlice.Range('A1').Font.Bold = 1;
                SheetSlice.Range('A1').Font.Size = 10;
                %
                SheetSlice.Range('B1').Value = sprintf('%s', nfo{j}.PatientID);
                SheetSlice.Range('B1').Font.Size =  10;

                SheetSlice.Range('A3').Value = sprintf('b values');
                SheetSlice.Range('A3').Font.Bold = 1;
                SheetSlice.Range('A3').Font.Size =  10;

                SheetSlice.Range('B3').Value = sprintf('%s', [lowb{lb} '_' highb{hb}]);
                SheetSlice.Range('B3').Font.Size =  10;

                SheetSlice.Range('A4').Value = sprintf('Series Description');
                SheetSlice.Range('A4').Font.Bold = 1;
                SheetSlice.Range('A4').Font.Size =  10;

                SheetSlice.Range('B4').Value = sprintf('%s', nfo{j}.SeriesDescription);
                SheetSlice.Range('B4').Font.Size =  10;
                %
                if strcmp(slicelocation{j},'Apex')
                    SheetSlice.Range('A7:A11').Value  = {'A' 'S' 'I' 'L' 'mean'}';
                    n = '11';
                else
                    SheetSlice.Range('A7:A13').Value  = {'A' 'AS' 'IS' 'I' 'IL' 'AL' 'mean'}';
                    n = '13';
                end

                metrics = {'MD';'FA';'AD';'RD';'HAd';'HAg';'absE2A';'TRA';'SA'};
                coln = 'A';
                for k=1:length(metrics) 
                    coln = coln+1;
                    SheetSlice.Range([char(coln) '6']).Value = metrics{k};
                    SheetSlice.Range([char(coln) '7:' char(coln) n]).Value = ...
                        SegSlice.means.(metrics{k}).(lowb{lb}).(highb{hb})';
                    coln = coln+1;
                    SheetSlice.Range([char(coln) '6']).Value = [metrics{k} 'std'];
                    SheetSlice.Range([char(coln) '7:' char(coln) n]).Value = ...
                        SegSlice.stds.(metrics{k}).(lowb{lb}).(highb{hb})';
                end

                % if isfield(SegmentedData,'SNRest')
                %     SheetSlice.Range('Y6').Value = 'SNR est';
                %     SheetSlice.Range(['Y7:Y' n]).Value = SegmentedData.SNRest';
                % end

                Shapes = SheetSlice.Shapes;
                % Base position
                basePos = SheetSlice.Range('A15').Top;

                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['MD_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                topleftfig = placeExcelFigure( Shapes, basePos, img );
                topleftfig.Left = 10;

                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['FA_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                fig1 = placeExcelFigure( Shapes, basePos, img );
                fig1.Left = topleftfig.Left + topleftfig.Width+10;

                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['HA_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                fig2 = placeExcelFigure( Shapes, basePos, img );
                fig2.Left = fig1.Left + fig1.Width+10;
                
                basePos = basePos + topleftfig.Height+10;

                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['HA_filt_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                fig1 = placeExcelFigure( Shapes, basePos, img );
                fig1.Left = 10;
                
                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['E2A_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                fig2 = placeExcelFigure( Shapes, basePos, img );
                fig2.Left = fig1.Left + fig1.Width+10;
                
                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['TRA_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                fig1 = placeExcelFigure( Shapes, basePos, img );
                fig1.Left = fig2.Left + fig2.Width+10;
                
                basePos = basePos + topleftfig.Height+10;
                
                img = fullfile(pwd,saveDir,[cardiacphases{i} '_' slicelocation{j}], ['SA_' (lowb{lb}) '_' highb{hb} '_' patID '.png']);
                fig1 = placeExcelFigure( Shapes, basePos, img );
                fig1.Left = 10;

                SheetMain.Activate;
                metrics = {'MD';'FA';'AD';'RD';'HAd';'HAg';'absE2A';'TRA';'SA'};
                coln = 'D';
                SheetMain.Range(['A' sprintf('%d',m)]).Value = cardiacphases{i};
                SheetMain.Range(['B' sprintf('%d',m)]).Value = slicelocation{j};
                SheetMain.Range(['C' sprintf('%d',m)]).Value = lowb{lb};
                SheetMain.Range(['D' sprintf('%d',m)]).Value = highb{hb};
                for k = 1:length(metrics)
                    coln=coln+1;
                    SheetMain.Range([char(coln) sprintf('%d',m)]).Value = SegSlice.means.(metrics{k}).(lowb{lb}).(highb{hb})(end);
                    coln=coln+1;
                    SheetMain.Range([char(coln) sprintf('%d',m)]).Value = SegSlice.stds.(metrics{k}).(lowb{lb}).(highb{hb})(end);
                end
                m = m+1;    
            end
        end
    end
    fprintf('');
end

end

function fig = placeExcelFigure( Shapes, basePos, img )

% Add image
fig = Shapes.AddPicture(img,0,1,10,basePos,-1,-1);
%fig.ScaleWidth(0.5,true);
%fig.ScaleHeight(0.5,true);
fig.LockAspectRatio = true;
% fig.Left = 10+fig.Width+10;
fig.Top = basePos;
% fig.Height = 400;
% if fig.Width > 800
%     fig.Width = 800;
% end
fig.Placement = 3; % xlFreeFloating

end