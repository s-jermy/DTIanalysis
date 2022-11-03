function [Excel,Workbook] = StartExcel
    % Get handle to Excel COM Server
    % Find an existing instance of Excel if possible
    try
        Excel = actxGetRunningServer('Excel.Application');
    catch ME
        if strcmp(ME.identifier,'MATLAB:COM:norunningserver')
            % Or start a new instance
            Excel = actxserver('Excel.Application');
        else
            rethrow(ME)
        end
    end

    % Set it to visible 
    set(Excel,'Visible',1);
    
    Workbook = invoke(Excel.Workbooks, 'Add');
end