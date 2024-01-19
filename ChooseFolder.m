function [cwd] = ChooseFolder(tag,ind)
%     in:
%     tag - name of folder (or project) where data will be saved
%     ind - batch index to start from, useful if execution fails
%     halfway though a batch

%     out:
%     cwd - current working directory of subject in {tag} at {ind}
%     
%     description:
%     Picks folder of subject when running StartScript as a batch
%     operation.

if isempty(ind)
    ind = 1;
end

cwd = '';
err = 0;

switch tag
    case 'steve_cmo'
        files={...
            % fullfile('CMO','20220816_1404_STEVE_CMO_001','BH'),...	
            fullfile('CMO','20230310_1035_STEVE_CMO_006','BH'),...	#1	
            fullfile('CMO','20230310_1035_STEVE_CMO_006','CS'),...	#2
            fullfile('CMO','20230217_1404_STEVE_CMO_005','BH'),...	#3
            fullfile('CMO','20230217_1404_STEVE_CMO_005','CS'),...	#4
            fullfile('CMO','20220816_1404_STEVE_CMO_002','BH'),...	#5
            fullfile('CMO','20220816_1404_STEVE_CMO_002','CS'),...	#6
            fullfile('CMO','20230203_1405_STEVE_CMO_004','BH'),...	#7
            fullfile('CMO','20230203_1405_STEVE_CMO_004','CS'),...	#8
            fullfile('CMO','20230310_1440_STEVE_CMO_007','BH'),...	#9
            fullfile('CMO','20230310_1440_STEVE_CMO_007','CS')...	#10
            };
    case 'steve_cubic'
        files={...
            fullfile('CUBIC','20210619_1014_STEVE_DTI_002','BH'),...	#1
            fullfile('CUBIC','20210619_1014_STEVE_DTI_002','CS'),...	#2
            fullfile('CUBIC','20210602_1812_STEVE_DTI_004','BH'),...	#3
            fullfile('CUBIC','20210602_1812_STEVE_DTI_004','CS'),...	#4
            fullfile('CUBIC','20210619_1221_STEVE_DTI_006','BH'),...	#5
            fullfile('CUBIC','20210619_1221_STEVE_DTI_006','CS'),...	#6
            fullfile('CUBIC','20211129_1706_STEVE_DTI_008','BH'),...	#7
            fullfile('CUBIC','20211129_1706_STEVE_DTI_008','CS'),...	#8
            fullfile('CUBIC','20210709_1621_STEVE_DTI_009','BH'),...	#9
            fullfile('CUBIC','20210709_1621_STEVE_DTI_009','CS'),...	#10
            fullfile('CUBIC','20210723_1530_STEVE_DTI_010','BH'),...	#11
            fullfile('CUBIC','20210723_1530_STEVE_DTI_010','CS'),...	#12
            fullfile('CUBIC','20210728_1420_STEVE_DTI_011','BH'),...	#13
            fullfile('CUBIC','20210728_1420_STEVE_DTI_011','CS'),...	#14
            fullfile('CUBIC','20210729_1434_STEVE_DTI_012','BH'),...	#15
            fullfile('CUBIC','20210729_1434_STEVE_DTI_012','CS'),...	#16
            fullfile('CUBIC','20211126_1427_STEVE_DTI_013','BH'),...	#17
            fullfile('CUBIC','20211126_1427_STEVE_DTI_013','CS'),...	#18
            fullfile('CUBIC','20220117_1341_STEVE_DTI_014','BH'),...	#19
            fullfile('CUBIC','20220117_1341_STEVE_DTI_014','CS'),...	#20
            fullfile('CUBIC','20220314_1602_STEVE_DTI_016','BH'),...	#21
            fullfile('CUBIC','20220314_1602_STEVE_DTI_016','CS'),...    #22
            fullfile('CUBIC','20220117_1341_STEVE_DTI_014','FB')...	    #23
            };
    case 'steve_cubic_64'
        files={...
            fullfile('CUBIC','20210619_1221_STEVE_DTI_006','CS_64dir'),...	#1
            fullfile('CUBIC','20210709_1621_STEVE_DTI_009','CS_64dir'),...	#2
            fullfile('CUBIC','20210723_1530_STEVE_DTI_010','CS_64dir'),...	#3
            fullfile('CUBIC','20210728_1420_STEVE_DTI_011','CS_64dir'),...	#4
            fullfile('CUBIC','20210729_1434_STEVE_DTI_012','CS_64dir'),...	#5
            fullfile('CUBIC','20211126_1427_STEVE_DTI_013','CS_64dir'),...	#6
            fullfile('CUBIC','20220117_1341_STEVE_DTI_014','CS_64dir')...	#7
            };
    case 'steve_cubic_sl'
        files={...
            fullfile('CUBIC','20210619_1014_STEVE_DTI_002','CS_sl'),...	#1
            fullfile('CUBIC','20210619_1221_STEVE_DTI_006','CS_sl'),...	#2
            fullfile('CUBIC','20211129_1706_STEVE_DTI_008','CS_sl'),...	#3
            fullfile('CUBIC','20210709_1621_STEVE_DTI_009','CS_sl'),...	#4
            fullfile('CUBIC','20210723_1530_STEVE_DTI_010','CS_sl'),...	#5
            fullfile('CUBIC','20210728_1420_STEVE_DTI_011','CS_sl'),...	#6
            fullfile('CUBIC','20210729_1434_STEVE_DTI_012','CS_sl'),...	#7
            fullfile('CUBIC','20220117_1341_STEVE_DTI_014','CS_sl')...	#8
            };
    case 'steve_oxford_2018'
        files={
            fullfile('Oxford','20180627_O3TPR_CD01_10258','siemensBH'),...	    #1
            fullfile('Oxford','20180627_O3TPR_CD01_10258','siemensGate'),...    #2
            fullfile('Oxford','20180627_O3TPR_CD01_10258','siemensNav'),...	    #3
            fullfile('Oxford','20180627_O3TPR_CD01_10258','steveNav'),...	    #4
            fullfile('Oxford','20180628_O3TPR_CD11_01_10275','siemensBH'),...	#5
            fullfile('Oxford','20180628_O3TPR_CD11_01_10275','siemensGate'),...	#6
            fullfile('Oxford','20180628_O3TPR_CD11_01_10275','siemensNav'),...	#7
            fullfile('Oxford','20180628_O3TPR_CD11_01_10275','steveNav'),...	#8
            fullfile('Oxford','20180629_O3TPR_C11_01_10286','siemensBH'),...	#9
            fullfile('Oxford','20180629_O3TPR_C11_01_10286','siemensGate'),...	#10
            fullfile('Oxford','20180629_O3TPR_C11_01_10286','siemensNav'),...	#11
            fullfile('Oxford','20180629_O3TPR_C11_01_10286','steveNav')...	    #12
            };
    case 'steve_oxford_2020'
        files={
            fullfile('Oxford','20200923_O3TPR_CD01_16789','siemensBH'),...	    #1
            fullfile('Oxford','20200923_O3TPR_CD01_16789','siemensGate'),...    #2
            fullfile('Oxford','20200923_O3TPR_CD01_16789','siemensNav'),...	    #3
            fullfile('Oxford','20200923_O3TPR_CD01_16789','steveNav'),...	    #4
            fullfile('Oxford','20201021_O3TPR_CD01_17059','siemensBH'),...	    #5
            fullfile('Oxford','20201021_O3TPR_CD01_17059','siemensGate'),...    #6
            fullfile('Oxford','20201021_O3TPR_CD01_17059','siemensNav'),...	    #7
            fullfile('Oxford','20201021_O3TPR_CD01_17059','steveNav')...	    #8
            };
    case 'steve_oxford_2021'
        files={
            fullfile('Oxford','20211125_O3TPR_CD01_20632_complete','siemensBH'),...	    #1
            fullfile('Oxford','20211125_O3TPR_CD01_20632_complete','siemensGate'),...   #2
            fullfile('Oxford','20211125_O3TPR_CD01_20632_complete','siemensNav'),...    #3
            fullfile('Oxford','20211125_O3TPR_CD01_20632_complete','steveNav'),...	    #4
            fullfile('Oxford','20211208_steveDTIAH_complete','siemensBH'),...           #5
            fullfile('Oxford','20211208_steveDTIAH_complete','siemensGate'),...         #6
            fullfile('Oxford','20211208_steveDTIAH_complete','siemensNav'),...          #7
            fullfile('Oxford','20211208_steveDTIAH_complete','steveNav'),...            #8
            fullfile('Oxford','20211222_SteveDTIFM_complete','siemensBH'),...           #9
            fullfile('Oxford','20211222_SteveDTIFM_complete','siemensGate2'),...        #10
            fullfile('Oxford','20211222_SteveDTIFM_complete','siemensNav2'),...         #11
            fullfile('Oxford','20211222_SteveDTIFM_complete','steveNav'),...            #12
            fullfile('Oxford','20220119_steveDTIhg','siemensBH'),...                    #13
            fullfile('Oxford','20220119_steveDTIhg','siemensGate'),...                  #14
            fullfile('Oxford','20220119_steveDTIhg','siemensNav'),...                   #15
            fullfile('Oxford','20220119_steveDTIhg','steveNav'),...                     #16
            fullfile('Oxford','20220408_SteveHM','siemensBH'),...                       #17
            fullfile('Oxford','20220408_SteveHM','siemensGate'),...                     #18
            fullfile('Oxford','20220408_SteveHM','siemensNav'),...                      #19
            fullfile('Oxford','20220408_SteveHM','steveNav')...                         #20
            };
    case 'zak'
        files={
            fullfile('PRISMA DICOMS','DTI20211021','1_'),...	                #1
            fullfile('PRISMA DICOMS','DTI20211027','1_'),...	                #2
            fullfile('PRISMA DICOMS','DTI20211130'),...	                        #3
            fullfile('TRIO DICOMS','20210806_DTI3748'),...	                    #4
            fullfile('TRIO DICOMS','20210908_DTI8246_1'),...	                #5
            fullfile('TRIO DICOMS','20211103_DTI6259'),...	                    #6
            fullfile('TRIO DICOMS','20211130_DTI6281'),...                      #7
            fullfile('DTI discrepancy cases','DICOMS','20210709_DTI4305'),...   #8
            fullfile('DTI discrepancy cases','DICOMS','20210727_DTI57'),...	    #9
            fullfile('DTI discrepancy cases','DICOMS','20210802_DTI7082'),...   #10
            fullfile('DTI discrepancy cases','DICOMS','20210819_DTI4327')...    #11
            };
    otherwise
        err = 1;
end

if ~err
    cwd = files{ind};
end

end