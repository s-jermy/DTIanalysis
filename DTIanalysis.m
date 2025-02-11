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
customMaps = false;
useMapMask = true;
allMaps = false;

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
            dataDirParent = '/Volumes/mri/UserFolders/jermy/DiffusionData';
        otherwise
            dataDirParent = pwd;
    end
end

%%
dicomdict('set','dicom-dict-dti.txt'); %set dicom dictionary for added dicom attributes
lastFunc = '';

if glyphs
    additionalID = 'glyph_dti';
elseif affine
    additionalID = 'affReg_HRcorr_dti';
else
    additionalID = 'HRcorr_dti'; %sj - tags for changes
end

if ~isempty(lowbLabels)
    lowbValues = cellfun(@(s) str2double(strjoin(regexp(s,'\d','match'),'')),lowbLabels);
    lowbFixed = min(lowbValues(:));
else
    lowbFixed = 50;
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
additionalID = [additionalID '_' splitdir{end}];
newfolder = false;

try
    dcmInfo = LoadFirstDicom(dirlisting); %load first valid dicom file from the chosen directory
catch
    warning('Folder "%s" could not be found or does not exist. Continuing...',dataDir);
    tmp = strsplit(splitdir{end-1},'_');
    dcmInfo.PatientID = char(join(tmp(2:end),'_'));
end

switch saveTag
    case 'steve_cmo'
        saveDir = fullfile(saveTag,dcmInfo.PatientName.FamilyName,additionalID);
    otherwise
        saveDir = fullfile(saveTag,dcmInfo.PatientID,additionalID);
end
% warning('off','MATLAB:MKDIR:DirectoryExists');

try
    if ~isfolder(saveDir)
        mkdir(saveDir); %create a new folder for the save directory
        newfolder = true;
    end
catch %unable to make directory (usually because of missing ID or an illegal character)
    saveDir = fullfile(saveTag,dcmInfo.PatientName.FamilyName,additionalID);
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
        saveDir = fullfile(saveTag,dcmInfo.PatientID,additionalID);
        if ~isfolder(saveDir)
            mkdir(saveDir);
            newfolder = true;
        end
    end
end
% warning('on','MATLAB:MKDIR:DirectoryExists');

%% load previous files if we have run this before
if ~newfolder
    try
        load(fullfile(saveDir,'lastFunc.mat')); %if an operation failed part way though execution lastFunc keeps track of the last succesful function
    catch
        warning('No vaild files were found in that directory. Continuing...');
        lastFunc = '';
    end
    
    %{
    lastFunc = 'CategoriseAndConstrain'; %override
    %}
    
    switch lastFunc
        case 'AnalyseDicoms' %next CategoriseAndConstrain
            try
                load(fullfile(saveDir,'Provisional.mat'),'Provisional*');
            catch
                lastFunc = '';
                %basically just redo everything
            end
        case 'CategoriseAndConstrain' %next RejectImages
            load(fullfile(saveDir,'Current.mat'),'Current*');
            load(fullfile(saveDir,'contours.mat'),'contours');
        case 'RejectImages' %next Registration
            load(fullfile(saveDir,'Clean.mat'),'Clean*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
                CleanInfo{l}.registrationComplete = 0;
            end
        case 'Registration' %next DefineROI
            load(fullfile(saveDir,'Clean.mat'),'Clean*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            for l = 1:length(CleanInfo)
                CleanInfo{l}.contoursDefined = 0;
            end
        case 'DefineROI' %next hrCorrection
            load(fullfile(saveDir,'Clean.mat'),'Clean*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'hrCorrection' %next Average
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'Average' %next CalculateTensor
            load(fullfile(saveDir,'CleanAver.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'CalculateTensor' %next DTIMaps
            load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
            load(fullfile(saveDir,'CleanAver.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        case 'DTIMaps' %next SegmentalAnalysis
            load(fullfile(saveDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(saveDir,'CleanAver.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
            end
        case 'SegmentalAnalysis' %next savePNGs
            load(fullfile(saveDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(saveDir,'CleanMaps.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'contours.mat'),'contours');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            if glyphs
                load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
            end
        case 'savePNGs' %next WriteExcelSheet or...
            load(fullfile(saveDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
            if glyphs %next GlyphDTI
                load(fullfile(saveDir,'CleanTensor.mat'),'Clean*');
                load(fullfile(saveDir,'CleanMaps.mat'),'Clean*');
                load(fullfile(saveDir,'contours.mat'),'contours');
            end
        case 'GlyphDTI' %next WriteExcelSheet
            load(fullfile(saveDir,'CleanSegs.mat'),'Clean*');
            load(fullfile(saveDir,'CleanHRcorr.mat'),'HR*');
            load(fullfile(saveDir,'Trace.mat'),'Trace');
        otherwise %start again
            lastFunc = ''; %just redo everything
    end
end

save(fullfile(saveDir,'Paths.mat'),'dataDir','saveDir','affine','glyphs','additionalID','lowbLabels','highbLabels');

%% load images
if isempty(lastFunc)
    InitialDicoms = LoadDicom(dirlisting); %✓
    % lastFunc = 'LoadDicom';

    [ProvisionalDiffusionDicoms,ProvisionalInfo] = AnalyseDicoms(InitialDicoms); %✓
    lastFunc = 'AnalyseDicoms';

    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Provisional.mat'),'ProvisionalDiffusionDicoms','ProvisionalInfo');
end

%% sort images by slice and phase
if strcmp(lastFunc,'AnalyseDicoms')
    [CurrentSlice,CurrentInfo,contours] = CategoriseAndConstrain(ProvisionalDiffusionDicoms,ProvisionalInfo,'RefLowB',lowbFixed); %✓
    lastFunc = 'CategoriseAndConstrain';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Current.mat'),'CurrentSlice','CurrentInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
end

%% remove low quality images
if strcmp(lastFunc,'CategoriseAndConstrain')
    [AHASliceLocations,figures] = RejectImages(CurrentSlice,CurrentInfo,contours); %✓
    lastFunc = 'RejectImages';

    %% create clean structures
    [CleanData,CleanInfo,~,CurrentInfo] = CleanStruct(CurrentSlice,CurrentInfo,figures,AHASliceLocations); %✓
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Current.mat'),'CurrentSlice','CurrentInfo');
    save(fullfile(saveDir,'Clean.mat'),'CleanData','CleanInfo');
    % save(fullfile(saveDir,'contours.mat'),'contours');

    SaveFigures(figures,saveDir,'RejectImages');

    close all; clear figures;
end

%% register and segment
if strcmp(lastFunc,'RejectImages')
    [CleanData,CleanInfo,Trace] = Registration(CleanData,CleanInfo,contours,affine,'RefLowB',lowbFixed); %✓
    lastFunc = 'Registration';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'Trace.mat'),'Trace');
end

if strcmp(lastFunc,'Registration')
    [CleanInfo,contours] = DefineROI(Trace,CleanInfo,contours,'RefLowB',lowbFixed); %✓
%     [CleanInfo,contours] = ResampleROI(CleanInfo,contours);
    lastFunc = 'DefineROI';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'Clean.mat'),'CleanData','CleanInfo');
    save(fullfile(saveDir,'contours.mat'),'contours');
end

%% apply corrections for heart rate and T1 relaxation
if strcmp(lastFunc,'DefineROI')
    [HRCorrData,HRCorrInfo] = hrAndT1Correction(CleanData,CleanInfo); %✓
    lastFunc = 'hrCorrection';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanHRcorr.mat'),'HRCorrData','HRCorrInfo');
end

%% get average images for each unique gradient direction
% should I get the SNR maps?
if strcmp(lastFunc,'hrCorrection')
    [CleanAverage,~] = Average(HRCorrData,HRCorrInfo); %✓ - fixed
    lastFunc = 'Average';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanAver.mat'),'CleanAverage');
end

%% begin actual DTI analysis
if strcmp(lastFunc,'Average')
    CleanTensor = CalculateTensor(CleanAverage); %✓
    lastFunc = 'CalculateTensor';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanTensor.mat'),'CleanTensor');
end

if strcmp(lastFunc,'CalculateTensor')
    CleanMaps = DTIMaps(CleanTensor,contours); %✓
    lastFunc = 'DTIMaps';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanMaps.mat'),'CleanMaps');
end

if strcmp(lastFunc,'DTIMaps')
    CleanSegments = SegmentalAnalysis(CleanMaps,CleanAverage,contours); %✓
    CleanHASegments = SegmentalHAAnalysis(CleanMaps,HRCorrInfo,contours); %✓
    CleanSegments = CombineSegs(CleanSegments,CleanHASegments);
    lastFunc = 'SegmentalAnalysis';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
    save(fullfile(saveDir,'CleanSegs.mat'),'CleanSegments');
end

% export images and data to excel
if strcmp(lastFunc,'SegmentalAnalysis')
    savePNGs(CleanMaps,HRCorrInfo,Trace,contours,saveDir,'LowB',lowbLabels,'HighB',highbLabels,'PrintAllMaps',allMaps,'CustomColourmap',customMaps,'RefLowB',lowbFixed); %✓
    lastFunc = 'savePNGs';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');
end

if strcmp(lastFunc,'savePNGs')&&glyphs
    figures = GlyphDTI(CleanTensor,CleanMaps,HRCorrInfo,contours,Trace,'LowB',lowbLabels,'HighB',highbLabels,'RefLowB',lowbFixed);
    SaveGlyphs(figures,saveDir);
    lastFunc = 'GlyphDTI';
    save(fullfile(saveDir,'lastFunc.mat'),'lastFunc');

    close all; clear figures;
end

if strcmp(lastFunc,'savePNGs')||strcmp(lastFunc,'GlyphDTI')
    if (ispc)
        warning('off','MATLAB:MKDIR:DirectoryExists');
        [Excel, Workbook] = StartExcel; %✓
        WriteExcelSheet(Excel,Workbook,CleanSegments,HRCorrInfo,saveDir,'LowB',lowbLabels,'HighB',highbLabels); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
        warning('on','MATLAB:MKDIR:DirectoryExists');
        saveAndCloseExcel(Excel,Workbook,saveDir,additionalID); %✓
    else
        WriteExcelSheetMac(CleanSegments,HRCorrInfo,saveDir,additionalID,'LowB',lowbLabels,'HighB',highbLabels); %✓ - I suggest pausing onedrive if you are saving into a onedrive folder
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
