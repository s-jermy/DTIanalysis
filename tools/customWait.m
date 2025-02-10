function customWait(event,hROI)

if strcmp(event.Key, 'return')  % 'return' corresponds to the Enter key
    hROI.InteractionsAllowed = 'none'; % Disable further editing
    uiresume;
end

% % Listen for mouse clicks on the ROI
% l = addlistener(hROI,'ROIClicked',@clickCallback);
% 
% % Block program execution
% hROI.Label = 'Adjust then Double click on ROI to finish';
% hROI.LabelAlpha = 0.5;
% uiwait;
% 
% % Remove listener
% delete(l);

end

% function clickCallback(~,evt)
% 
% if strcmp(evt.SelectionType,'double')
%     uiresume;
% end
% 
% end