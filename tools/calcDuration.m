function [dur,dur_corr,gap] = calcDuration(nfo)

slices = length(nfo);

acq = [nfo.Info.AcqTime];
sn = [nfo.Info.SeriesNumber];

[acq,idx] = sort(acq);
sn = sn(idx);

dur = acq(end) - acq(1);

% disp('Uncorrected:')
% disp(dur);

[Csn,ia,~] = unique(sn);
diff = acq(2:end)-acq(1:end-1);
acq_gap = diff(ia(2:end)-1);
acq_gaps = seconds(acq_gap);
diff(ia(2:end)-1) = []; %remove gaps

sn_diff = Csn(2:end)-Csn(1:end-1);
if any(sn_diff>3)
    acq_gap = acq_gap./floor(sn_diff/3);
end

o = isoutlier(acq_gaps,'gesd'); %find outliers in the gaps between scans
if ~any(o)
    o = isoutlier(acq_gaps);
end
acq_gap(o) = mean(acq_gap(~o));

gap = sum(acq_gap);
dur_corr = sum(diff) + gap;

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
