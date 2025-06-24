function saveAndCloseExcel(Excel,Workbook,saveDir,AddID)
    % Save the workbook and Close Excel

    Workbook.Sheets(1).Item(1).Activate;
    outputFilename = fullfile(pwd,saveDir,[AddID '.xlsx']);
    bDone = false;
    while ~bDone
        try
            Workbook.Application.DisplayAlerts = false;
            invoke(Workbook, 'SaveAs', outputFilename);
            bDone = true;
        catch ME
            drawnow

            fprintf('%s\n\n',...
                ['Error saving XLSX file.' newline newline 'Filename: ' outputFilename newline newline ME.getReport()])
        %     
        end
    end
    Workbook.Close;
    Excel.Quit;
end