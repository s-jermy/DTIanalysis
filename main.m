% for i = start:finish
%     DTIanalysis('key1',value1,'key2',value2,...)
% end

for i = 1:23
    saveTag = 'steve_cubic';
    batchFlag = true;
    batchInd = i;
    glyphs = true;
    lowb = {'b50'};
    highb = {'b450'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb);
end
for i = 1:7
    saveTag = 'steve_cubic_64';
    batchFlag = true;
    batchInd = i;
    glyphs = true;
    lowb = {'b50'};
    highb = {'b450'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb);
end
for i = 1:8
    saveTag = 'steve_cubic_sl';
    batchFlag = true;
    batchInd = i;
    glyphs = false;
    lowb = {'b50'};
    highb = {'b450'};
    customMaps = true;
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb,'CustomColourmap',customMaps);
end
for i = 1:12
    saveTag = 'steve_oxford_2018';
    batchFlag = true;
    batchInd = i;
    glyphs = false;
    lowb = {'b50','b350'};
    highb = {'b350','b450','b550','b650'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb);
end
for i = 1:8
    saveTag = 'steve_oxford_2020';
    batchFlag = true;
    batchInd = i;
    glyphs = false;
    lowb = {'b50','b350'};
    highb = {'b350','b450','b550','b650'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb);
end
for i = 1:20
    saveTag = 'steve_oxford_2021';
    batchFlag = true;
    batchInd = i;
    glyphs = false;
    lowb = {'b50','b350'};
    highb = {'b350','b450','b550','b650'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb);
end
for i = 1:10
    saveTag = 'steve_cmo';
    batchFlag = true;
    batchInd = i;
    glyphs = false;
    lowb = {'b50'};
    highb = {'b450'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'LowB',lowb,'HighB',highb);
end
for i = 1:11
    saveTag = 'zak';
    batchFlag = true;
    batchInd = i;
    glyphs = false;
    affine = false;
    lowb = {'b15'};
    highb = {'b350'};
    DTIanalysis('SaveTag',saveTag,'RunBatch',batchFlag,'BatchIndex',batchInd,'TensorGlyphs',glyphs,'AffineReg',affine,'LowB',lowb,'HighB',highb);
end