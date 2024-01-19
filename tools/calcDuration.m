function [dur,dur_corr] = calcDuration(nfo)

slices = length(nfo);

acq = [nfo.Info.AcqTime];
sn = [nfo.Info.SeriesNumber];

[acq,idx] = sort(acq);
sn = sn(idx);

dur = acq(end) - acq(1);

% disp('Uncorrected:')
% disp(dur);

[~,ia,~] = unique(sn);
diff = acq(2:end)-acq(1:end-1);
gap = diff(ia(2:end)-1);
gaps = seconds(gap);
diff(ia(2:end)-1) = []; %remove gaps

o = isoutlier(gaps,'gesd'); %find outliers in the gaps between scans
if ~any(o)
    o = isoutlier(gaps);
end
gap(o) = mean(gap(~o));

dur_corr = sum(diff) + sum(gap);

% diff = duration(0,0,0,0,"Format","dd:hh:mm:ss.SSSS");
% maxacq = diff;
% for i=1:numel(a)
%     acq1 = acq(c==i);
% 
%     minacq = min(acq1);
%     gap(i) = minacq - maxacq;
%     maxacq = max(acq1);
%     diff = diff+(maxacq - minacq);
% end
% 
% gap(1) = [];
% 
% disp('Corrected:');
% disp(dur_corr);
