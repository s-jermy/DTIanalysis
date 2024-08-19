% for i = start:finish
%     DTIanalysis({'saveTag'},{batchFlag},{batchInd},{glyphs},{affine})
% end

for i = 1:11
    DTIanalysis('zak',1,i,0,1);
end