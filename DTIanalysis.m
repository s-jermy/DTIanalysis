%% New DTI script
function DTIanalysis(varargin)
% DTIANALYSIS({saveTag} {batchFlag} {batchInd} {glyphs} {affine})
%     in:
%     saveTag - name of folder (or project) where data will be saved
%     batchFlag - flag to set if StartScript will be running multiple cases
%     at once
%     batchInd - batch index to start from, useful if execution fails
%     halfway though a batch
%     glyphs - true/{false} show superquad glyphs of tensors
%     affine - {true}=perform affine registration / false=perform simple
%     registration
%     lowbLabels - labels of low b-values to output
%     highbLabels - labels of high b-values to output
%     customMaps - true=use custom colourmaps from cardiac_DTI_colormaps
%     git / {false}=use default matlab colours🥱
%     useMapMask - {true}/false use roi mask when printing maps
%     allMaps - true=print all dti maps / {false}=print md fa ha e2a
%     EstimateSNR - {true}/false calculate SNR values
%     
%     description:
%     Code for running DTIanalysis. If no inputs are given, it is
%     equivalent to running DTIanalysis('default',0). The 'main.m' script
%     is used to call DTIanalysis function for a specific case.
% 
%     REQUIRED TOOLBOXES:
%     Curve Fitting toolbox
%     Image Processing toolbox

%% instance variables
saveTag = 'default';
batchFlag = false;
batchInd = 1;
glyphs = false;
affine = true;
lowbLabels = {};
highbLabels = {};
lowbFixed = [];
customMaps = false;
useMapMask = true;
allMaps = false;
extras = false;
override_nf = '';
t1 = true;
estimate_snr = false;

if mod(numel(varargin), 2) ~= 0
    error('Arguments must be provided in key-value pairs.');
end

for i = 1:2:numel(varargin)
    key = varargin{i};
    value = varargin{i+1};

    switch key
        case 'SaveTag'
            saveTag = value;
        case 'RunBatch'
            batchFlag = value;
        case 'BatchIndex'
            batchInd = value;
        case 'TensorGlyphs'
            glyphs = value;
        case 'AffineReg'
            affine = value;
        case 'LowB'
            lowbLabels = value;
        case 'HighB'
            highbLabels = value;
        case 'RefLowB'
            lowbFixed = value;
        case 'T1Corr'
            t1 = value;
        case 'CustomColourmap'
            customMaps = value;
        case 'MapMask'
            useMapMask = value;
        case 'PrintAllMaps'
            allMaps = value;
        case 'PrintExtras'
            extras = value;
        case 'EstimateSNR'
            estimate_snr = value;
        case 'OverrideNextFunc'
            override_nf = value;
        otherwise
            warning('Unknown parameter: %s', key);
    end
end

% clearvars
close all

addpath(genpath('tools')); %add tools and subfolders to the search path

%% save directory for output files for different projects
saveTagCell = regexp(saveTag,'_','split');
if ispc
    switch saveTagCell{1}
        % case 'saveTag'
        %     dataDirParent = 'C:\your\workspace\folder'; %change as needed
        case 'steve'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData';
        case 'zak'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData\Zak';
        case 'test'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData';
        case 'steam'
            dataDirParent = 'C:\Users\User\Documents\DiffusionData';
        otherwise
            dataDirParent = pwd;
    end
elseif ismac
    switch saveTagCell{1}
        % case 'saveTag'
        %     dataDirParent = '/your/workspace/folder/'; %change as needed
        case 'steve'
            dataDirParent = '/Volumes/mri/UserFolders/Steve/DiffusionData';
        otherwise
            dataDirParent = pwd;
    end
end

%%
dicomdict('set','dicom-dict-dti.txt'); %set dicom dictionary for added dicom attributes
nextFunc = '';

if glyphs
    analysisTag = 'glyph';
elseif affine
    analysisTag = 'affReg';
else
    analysisTag = 'simReg';
end
if t1
    analysisTag = [analysisTag '_HRcorr']; %sj - tags for changes
end

analysisTag = [analysisTag '_dti'];

if isempty(lowbFixed)
    if ~isempty(lowbLabels)
        lowbValues = cellfun(@(s) str2double(strjoin(regexp(s,'\d','match'),'')),lowbLabels);
        lowbFixed = min(lowbValues(:));
    else
        lowbFixed = 0;
    end
end

%% check/create folders
dataDir = '';

if batchFlag
    dataDir = ChooseFolder(saveTag,batchInd);
    dataDir = fullfile(dataDirParent,dataDir); %get folder of current subject
end

if isempty(dataDir)
    dataDir = uigetdir(dataDirParent); %choose bottom level folder of images - i.e. folder containing no subfolders
end
dirlisting = dir(fullfile(dataDir,'**')); %find all in the main directory including subfolders

splitdir = regexp(dataDir,filesep,'split');
splitdir = splitdir(~cellfun('isempty',splitdir));
folderTag = splitdir{end};
newfolder = false;
newanalysis = false;

try
    dcmInfo = LoadFirstDicom(dirlisting); %load first valid dicom file from the chosen directory
catch
    error('LoadFirstDicom: There was a problem loading the first dicom from folder "%s".',dataDir);
end

switch saveTag
    case 'steve_cmo'
        saveDir = fullfile('output',saveTag,dcmInfo.PatientName.FamilyName,folderTag);
    otherwise
        saveDir = fullfile('output',saveTag,dcmInfo.PatientID,folderTag);
end

try
    if ~isfolder(saveDir)
        mkdir(saveDir); %create a new folder for the save directory
        newfolder = true;
    end
catch %unable to make directory (usually because of missing ID or an illegal character)
    saveDir = fullfile('output',saveTag,dcmInfo.PatientName.FamilyName,folderTag);
    try %try again with patient name
        if ~isfolder(saveDir)
            mkdir(saveDir);
            newfolder = true;
        end
    catch
        regex = '[\W]'; %in case there are illegal characters
        pat = regexpPattern(regex);
        ind = strfind(dcmInfo.PatientID,pat); %find and remove illegal characters
        dcmInfo.PatientID(ind)='';
        saveDir = fullfile('output',saveTag,dcmInfo.PatientID,folderTag);
        if ~isfolder(saveDir)
            mkdir(saveDir);
            newfolder = true;
        end
    end
end

anaDir = fullfile(saveDir,analysisTag);
% warning('off','MATLAB:MKDIR:DirectoryExists');

if ~isfolder(anaDir)
    mkdir(anaDir); %create a new folder for the save directory
    newanalysis = true;
end
% warning('on','MATLAB:MKDIR:DirectoryExists');

%% load previous files if we have run this before
if ~newfolder
    try
        load(fullfile(saveDir,'contours.mat'),'contours'); %
    catch
        warning('contours: No vaild files were found in that directory. Continuing...');
        contours = struct();
    end
    try
        load(fullfile(saveDir,'FilesToUse.mat'),'FilesToUse'); %
    catch
        warning('FilesToUse: No vaild files were found in that directory. Continuing...');
        FilesToUse = {};
    end
    try
        load(fullfile(saveDir,'Provisional.mat'),'Provisional*'); %
        if(length(who('-regexp','Provisional*'))==2)
            nextFunc = 'AnalyseDicoms'; %next CategoriseAndConstrain
        end
    catch
        warning('Provisional: No vaild files were found in that directory. Continuing...');
    end
end
if ~newanalysis
    try
        load(fullfile(anaDir,'nextFunc.mat'),'nextFunc'); %if an operation failed part way though execution nextFunc keeps track of the function about to be executed
    catch
        try
            load(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
            nextFunc = lastFunc;
        catch
            warning('No vaild files were found in that directory. Continuing...');
        end
    end
    
    %%{
    if ~isempty(override_nf)
        nextFunc = override_nf; %override
    end
    %}
    
    switch nextFunc
        case 'CategoriseAndConstrain' %next CategoriseAndConstrain
            if(length(who('-regexp','Provisional*'))~=2)
                nextFunc = ''; %start from scratch
            end
        case 'RejectImages' %next RejectImages
            load(fullfile(anaDir,'Current.mat'),'Current*');
        case 'Registration' %next Registration
            load(fullfile(anaDir,'Clean.mat'),'Clean*');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
                CleanInfo{l}.registrationComplete = 0;
            end
        case 'DefineROI' %next DefineROI
            load(fullfile(anaDir,'Clean.mat'),'Clean*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
            end
        case 'hrCorrection' %next hrCorrection
            load(fullfile(anaDir,'Clean.mat'),'Clean*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'Average' %next Average
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'CalculateTensor' %next CalculateTensor
            load(fullfile(anaDir,'CleanAver.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'DTIMaps' %next DTIMaps
            load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
            load(fullfile(anaDir,'CleanAver.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'SegmentalAnalysis' %next SegmentalAnalysis
            load(fullfile(anaDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(anaDir,'CleanAver.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
            end
        case 'savePNGs' %next savePNGs
            load(fullfile(anaDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(anaDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
            end
        case 'WriteExcelSheet' %next WriteExcelSheet or...
            load(fullfile(anaDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            if glyphs %next GlyphDTI
                load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
                load(fullfile(anaDir,'CleanMaps.mat'),'Clean*');
            end
        case 'WriteExcelSheet_ng' %next WriteExcelSheet
            load(fullfile(anaDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'Finished'
            % nothing to do
        otherwise %start again
            nextFunc = ''; %just redo everything
    end
end

save(fullfile(saveDir,'Paths.mat'),'dataDir','saveDir','affine','glyphs','analysisTag','lowbLabels','highbLabels');

%% load images
if isempty(nextFunc)
    InitialDicoms = LoadDicom(dirlisting); %✓
    % nextFunc = 'AnalyseDicoms';

    [ProvisionalDiffusionDicoms,ProvisionalInfo] = AnalyseDicoms(InitialDicoms); %✓
    nextFunc = 'CategoriseAndConstrain';

    save(fullfile(saveDir,'Provisional.mat'),'ProvisionalDiffusionDicoms','ProvisionalInfo');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%%{
%% sort images by slice and phase
if strcmp(nextFunc,'CategoriseAndConstrain')
    if ~exist('contours','var')
        contours = struct();
    end
    [CurrentSlice,CurrentInfo,contours] = CategoriseAndConstrain(ProvisionalDiffusionDicoms,ProvisionalInfo,contours,'RefLowB',lowbFixed); %✓
    nextFunc = 'RejectImages';
    save(fullfile(anaDir,'Current.mat'),'CurrentSlice','CurrentInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%% remove low quality images
if strcmp(nextFunc,'RejectImages')
    if ~exist('FilesToUse','var')
        FilesToUse = {};
    end
    [AHASliceLocations,figures] = RejectImages(CurrentSlice,CurrentInfo,contours,FilesToUse); %✓

    %% create clean structures
    [CleanData,CleanInfo,FilesToUse] = CleanStruct(CurrentSlice,CurrentInfo,figures,AHASliceLocations); %✓
    
    save(fullfile(anaDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'FilesToUse.mat'),'FilesToUse');
    % save(fullfile(saveDir,'contours.mat'),'contours');

    SaveFigures(figures,anaDir,'RejectImages');

    close all; clear figures;

    nextFunc = 'Registration';
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%% register and segment
if strcmp(nextFunc,'Registration')
    [CleanData,CleanInfo,Trace] = Registration(CleanData,CleanInfo,contours,affine,'RefLowB',lowbFixed); %✓
    nextFunc = 'DefineROI';
    save(fullfile(anaDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(anaDir,'Trace.mat'),'Trace');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

if strcmp(nextFunc,'DefineROI')
    [CleanInfo,contours] = DefineROI(Trace,CleanInfo,contours,'RefLowB',lowbFixed); %✓
%     [CleanInfo,contours] = ResampleROI(CleanInfo,contours);
    nextFunc = 'hrCorrection';
    save(fullfile(anaDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%% apply corrections for heart rate and T1 relaxation
if strcmp(nextFunc,'hrCorrection')
    [CorData,CorInfo] = hrAndT1Correction(CleanData,CleanInfo,'T1Corr',t1); %✓
    nextFunc = 'Average';
    save(fullfile(anaDir,'CleanCor.mat'),'CorData','CorInfo');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%% get average images for each unique gradient direction
if strcmp(nextFunc,'Average')
    CleanAverage = Average(CorData,CorInfo); %✓ - fixed
    nextFunc = 'CalculateTensor';
    save(fullfile(anaDir,'CleanAver.mat'),'CleanAverage');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%% begin actual DTI analysis
if strcmp(nextFunc,'CalculateTensor')
    CleanTensor = CalculateTensor(CleanAverage); %✓
    nextFunc = 'DTIMaps';
    save(fullfile(anaDir,'CleanTensor.mat'),'CleanTensor');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

if strcmp(nextFunc,'DTIMaps')
    CleanMaps = DTIMaps(CleanTensor,contours); %✓
    nextFunc = 'SegmentalAnalysis';
    save(fullfile(anaDir,'CleanMaps.mat'),'CleanMaps');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

if strcmp(nextFunc,'SegmentalAnalysis')
    CleanSegments = SegmentalAnalysis(CleanMaps,CleanAverage,contours); %✓
    CleanHASegments = SegmentalHAAnalysis(CleanMaps,CorInfo,contours); %✓
    CleanSegments = CombineSegs(CleanSegments,CleanHASegments);
    nextFunc = 'savePNGs';
    save(fullfile(anaDir,'CleanSegs.mat'),'CleanSegments');
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

% export images and data to excel
if strcmp(nextFunc,'savePNGs')
    savePNGs(CleanMaps,CorInfo,Trace,contours,anaDir,'LowB',lowbLabels,'HighB',highbLabels,'PrintAllMaps',allMaps,'CustomColourmap',customMaps,'RefLowB',lowbFixed,'MapMask',useMapMask,'PrintExtras',extras); %✓
    nextFunc = 'WriteExcelSheet';
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

if strcmp(nextFunc,'WriteExcelSheet')&&glyphs
    figures = GlyphDTI(CleanTensor,CleanMaps,CorInfo,contours,Trace,'LowB',lowbLabels,'HighB',highbLabels,'RefLowB',lowbFixed);
    SaveGlyphs(figures,anaDir);
    nextFunc = 'WriteExcelSheet_ng'; %no glyphs
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');

    close all; clear figures;
end

if estimate_snr
    %[SplitData,SplitInfo] = RepetitionSplit(CorData,CorInfo); %might come back to this one day, but it is not this day
    CleanSNR = CalculateSNR(CorData,CorInfo,contours);
    save(fullfile(anaDir,'CleanSNR.mat'),'CleanSNR');
else
    CleanSNR = [];
end

if strcmp(nextFunc,'WriteExcelSheet')||strcmp(nextFunc,'WriteExcelSheet_ng')
    if (ispc) %SNR not implemented
        warning('off','MATLAB:MKDIR:DirectoryExists');
        [Excel, Workbook] = StartExcel; %✓
        WriteExcelSheet(Excel,Workbook,CleanSegments,CorInfo,anaDir,'LowB',lowbLabels,'HighB',highbLabels,'EstimateSNR',estimate_snr,'SNR',CleanSNR); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
        warning('on','MATLAB:MKDIR:DirectoryExists');
        saveAndCloseExcel(Excel,Workbook,anaDir,analysisTag); %✓
    else
        WriteExcelSheetMac(CleanSegments,CorInfo,anaDir,analysisTag,'LowB',lowbLabels,'HighB',highbLabels,'EstimateSNR',estimate_snr,'SNR',CleanSNR); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
    end
    nextFunc = 'Finished';
    save(fullfile(anaDir,'nextFunc.mat'),'nextFunc');
end

%% fix matlab stupidity
% When you use plot/plot3/quiver/etc in Matlab it uses a right-handed
% coordinate sytem which makes sense. However, if you first use
% imshow/imagesc/etc Matlab will use a left-handed coordinate system for no
% obvious reason. This can be fixed by making some adjustments to the
% y-axis.

% figure;
% ax = imshow(Trace{1}{1},[]);
% ax.YData = fliplr(ax.YData);
% ax.Parent.YDir = 'normal';
end

%}
