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
t1 = true;

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
lastFunc = '';

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
    error('There was a problem loading the first dicom from folder "%s".',dataDir);
end

switch saveTag
    case 'steve_cmo'
        saveDir = fullfile(saveTag,dcmInfo.PatientName.FamilyName,folderTag);
    otherwise
        saveDir = fullfile(saveTag,dcmInfo.PatientID,folderTag);
end

anaDir = fullfile(saveDir,analysisTag);
% warning('off','MATLAB:MKDIR:DirectoryExists');

try
    if ~isfolder(saveDir)
        mkdir(saveDir); %create a new folder for the save directory
        newfolder = true;
    end
catch %unable to make directory (usually because of missing ID or an illegal character)
    saveDir = fullfile(saveTag,dcmInfo.PatientName.FamilyName,folderTag,analysisTag);
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
        saveDir = fullfile(saveTag,dcmInfo.PatientID,folderTag,analysisTag);
        if ~isfolder(saveDir)
            mkdir(saveDir);
            newfolder = true;
        end
    end
end

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
            lastFunc = 'AnalyseDicoms'; %next CategoriseAndConstrain
        end
    catch
        warning('Provisional: No vaild files were found in that directory. Continuing...');
    end
end
if ~newanalysis
    try
        load(fullfile(anaDir,'lastFunc.mat'),'lastFunc'); %if an operation failed part way though execution lastFunc keeps track of the last succesful function
    catch
        warning('No vaild files were found in that directory. Continuing...');
    end
    
    %{
    lastFunc = 'CategoriseAndConstrain'; %override
    %}
    
    switch lastFunc
        case 'AnalyseDicoms' %next CategoriseAndConstrain
            if(length(who('-regexp','Provisional*'))~=2)
                lastFunc = ''; %start from scratch
            end
        case 'CategoriseAndConstrain' %next RejectImages
            load(fullfile(anaDir,'Current.mat'),'Current*');
        case 'RejectImages' %next Registration
            load(fullfile(anaDir,'Clean.mat'),'Clean*');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
                CleanInfo{l}.registrationComplete = 0;
            end
        case 'Registration' %next DefineROI
            load(fullfile(anaDir,'Clean.mat'),'Clean*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
            end
        case 'DefineROI' %next hrCorrection
            load(fullfile(anaDir,'Clean.mat'),'Clean*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'hrCorrection' %next Average
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'Average' %next CalculateTensor
            load(fullfile(anaDir,'CleanAver.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'CalculateTensor' %next DTIMaps
            load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
            load(fullfile(anaDir,'CleanAver.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        case 'DTIMaps' %next SegmentalAnalysis
            load(fullfile(anaDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(anaDir,'CleanAver.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
            end
        case 'SegmentalAnalysis' %next savePNGs
            load(fullfile(anaDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(anaDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
            end
        case 'savePNGs' %next WriteExcelSheet or...
            load(fullfile(anaDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
            if glyphs %next GlyphDTI
                load(fullfile(anaDir,'CleanTensor.mat'),'Clean*');
                load(fullfile(anaDir,'CleanMaps.mat'),'Clean*');
            end
        case 'GlyphDTI' %next WriteExcelSheet
            load(fullfile(anaDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(anaDir,'CleanCor.mat'),'Cor*');
            load(fullfile(anaDir,'Trace.mat'),'Trace');
        otherwise %start again
            lastFunc = ''; %just redo everything
    end
end

save(fullfile(saveDir,'Paths.mat'),'dataDir','saveDir','affine','glyphs','analysisTag','lowbLabels','highbLabels');

%% load images
if isempty(lastFunc)
    InitialDicoms = LoadDicom(dirlisting); %✓
    % lastFunc = 'LoadDicom';

    [ProvisionalDiffusionDicoms,ProvisionalInfo] = AnalyseDicoms(InitialDicoms); %✓
    lastFunc = 'AnalyseDicoms';

    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Provisional.mat'),'ProvisionalDiffusionDicoms','ProvisionalInfo');
end

%%{
%% sort images by slice and phase
if strcmp(lastFunc,'AnalyseDicoms')
    [CurrentSlice,CurrentInfo,contours] = CategoriseAndConstrain(ProvisionalDiffusionDicoms,ProvisionalInfo,contours,'RefLowB',lowbFixed); %✓
    lastFunc = 'CategoriseAndConstrain';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'Current.mat'),'CurrentSlice','CurrentInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
end

%% remove low quality images
if strcmp(lastFunc,'CategoriseAndConstrain')
    [AHASliceLocations,figures] = RejectImages(CurrentSlice,CurrentInfo,contours,FilesToUse); %✓

    %% create clean structures
    [CleanData,CleanInfo,FilesToUse] = CleanStruct(CurrentSlice,CurrentInfo,figures,AHASliceLocations); %✓
    lastFunc = 'RejectImages';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'FilesToUse.mat'),'FilesToUse');
    % save(fullfile(saveDir,'contours.mat'),'contours');

    SaveFigures(figures,anaDir,'RejectImages');

    close all; clear figures;
end

%% register and segment
if strcmp(lastFunc,'RejectImages')
    [CleanData,CleanInfo,Trace] = Registration(CleanData,CleanInfo,contours,affine,'RefLowB',lowbFixed); %✓
    lastFunc = 'Registration';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(anaDir,'Trace.mat'),'Trace');
end

if strcmp(lastFunc,'Registration')
    [CleanInfo,contours] = DefineROI(Trace,CleanInfo,contours,'RefLowB',lowbFixed); %✓
%     [CleanInfo,contours] = ResampleROI(CleanInfo,contours);
    lastFunc = 'DefineROI';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
end

%% apply corrections for heart rate and T1 relaxation
if strcmp(lastFunc,'DefineROI')
    [CorData,CorInfo] = hrAndT1Correction(CleanData,CleanInfo,'T1Corr',t1); %✓
    lastFunc = 'hrCorrection';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'CleanCor.mat'),'CorData','CorInfo');
end

%% get average images for each unique gradient direction
% should I get the SNR maps?
if strcmp(lastFunc,'hrCorrection')
    [CleanAverage,~] = Average(CorData,CorInfo); %✓ - fixed
    lastFunc = 'Average';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'CleanAver.mat'),'CleanAverage');
end

%% begin actual DTI analysis
if strcmp(lastFunc,'Average')
    CleanTensor = CalculateTensor(CleanAverage); %✓
    lastFunc = 'CalculateTensor';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'CleanTensor.mat'),'CleanTensor');
end

if strcmp(lastFunc,'CalculateTensor')
    CleanMaps = DTIMaps(CleanTensor,contours); %✓
    lastFunc = 'DTIMaps';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'CleanMaps.mat'),'CleanMaps');
end

if strcmp(lastFunc,'DTIMaps')
    CleanSegments = SegmentalAnalysis(CleanMaps,CleanAverage,contours); %✓
    CleanHASegments = SegmentalHAAnalysis(CleanMaps,CorInfo,contours); %✓
    CleanSegments = CombineSegs(CleanSegments,CleanHASegments);
    lastFunc = 'SegmentalAnalysis';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(anaDir,'CleanSegs.mat'),'CleanSegments');
end

% export images and data to excel
if strcmp(lastFunc,'SegmentalAnalysis')
    savePNGs(CleanMaps,CorInfo,Trace,contours,anaDir,'LowB',lowbLabels,'HighB',highbLabels,'PrintAllMaps',allMaps,'CustomColourmap',customMaps,'RefLowB',lowbFixed,'MapMask',useMapMask); %✓
    lastFunc = 'savePNGs';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');
end

if strcmp(lastFunc,'savePNGs')&&glyphs
    figures = GlyphDTI(CleanTensor,CleanMaps,CorInfo,contours,Trace,'LowB',lowbLabels,'HighB',highbLabels,'RefLowB',lowbFixed);
    SaveGlyphs(figures,anaDir);
    lastFunc = 'GlyphDTI';
    save(fullfile(anaDir,'lastFunc.mat'),'lastFunc');

    close all; clear figures;
end

if strcmp(lastFunc,'savePNGs')||strcmp(lastFunc,'GlyphDTI')
    if (ispc)
        warning('off','MATLAB:MKDIR:DirectoryExists');
        [Excel, Workbook] = StartExcel; %✓
        WriteExcelSheet(Excel,Workbook,CleanSegments,CorInfo,anaDir,'LowB',lowbLabels,'HighB',highbLabels); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
        warning('on','MATLAB:MKDIR:DirectoryExists');
        saveAndCloseExcel(Excel,Workbook,anaDir,analysisTag); %✓
    else
        WriteExcelSheetMac(CleanSegments,CorInfo,anaDir,analysisTag,'LowB',lowbLabels,'HighB',highbLabels); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
    end
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
