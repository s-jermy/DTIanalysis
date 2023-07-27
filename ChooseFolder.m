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
            % 'CMO\20220816_1404_STEVE_CMO_001\BH',...	
            % 'CMO\20230310_1035_STEVE_CMO_006\BH',...	
            % 'CMO\20230310_1035_STEVE_CMO_006\CS',...	
            % 'CMO\20230217_1404_STEVE_CMO_005\BH',...
            % 'CMO\20230217_1404_STEVE_CMO_005\CS',...
            'CMO\20220816_1404_STEVE_CMO_002\BH',...	#1
            'CMO\20220816_1404_STEVE_CMO_002\CS',...	#2
            'CMO\20230203_1405_STEVE_CMO_004\BH',...	#3
            'CMO\20230203_1405_STEVE_CMO_004\CS',...	#4
            'CMO\20230310_1440_STEVE_CMO_007\BH',...	#5
            'CMO\20230310_1440_STEVE_CMO_007\CS',...	#6
            };
    case 'steve_cubic'
        files={...
            'CUBIC\20210619_1014_STEVE_DTI_002\BH',...	#1
            'CUBIC\20210619_1014_STEVE_DTI_002\CS',...	#2
            'CUBIC\20210602_1812_STEVE_DTI_004\BH',...	#3
            'CUBIC\20210602_1812_STEVE_DTI_004\CS',...	#4
            'CUBIC\20210619_1221_STEVE_DTI_006\BH',...	#5
            'CUBIC\20210619_1221_STEVE_DTI_006\CS',...	#6
            'CUBIC\20211129_1706_STEVE_DTI_008\BH',...	#7
            'CUBIC\20211129_1706_STEVE_DTI_008\CS',...	#8
            'CUBIC\20210709_1621_STEVE_DTI_009\BH',...	#9
            'CUBIC\20210709_1621_STEVE_DTI_009\CS',...	#10
            'CUBIC\20210723_1530_STEVE_DTI_010\BH',...	#11
            'CUBIC\20210723_1530_STEVE_DTI_010\CS',...	#12
            'CUBIC\20210728_1420_STEVE_DTI_011\BH',...	#13
            'CUBIC\20210728_1420_STEVE_DTI_011\CS',...	#14
            'CUBIC\20210729_1434_STEVE_DTI_012\BH',...	#15
            'CUBIC\20210729_1434_STEVE_DTI_012\CS',...	#16
            'CUBIC\20211126_1427_STEVE_DTI_013\BH',...	#17
            'CUBIC\20211126_1427_STEVE_DTI_013\CS',...	#18
            'CUBIC\20220117_1341_STEVE_DTI_014\BH',...	#19
            'CUBIC\20220117_1341_STEVE_DTI_014\CS',...	#20
            'CUBIC\20220117_1341_STEVE_DTI_014\FB',...	#21
            'CUBIC\20220314_1602_STEVE_DTI_016\BH',...	#22
            'CUBIC\20220314_1602_STEVE_DTI_016\CS'...	#23
            };
    case 'steve_cubic_64'
        files={...
            'CUBIC\20210619_1221_STEVE_DTI_006\CS_64dir',...	#1
            'CUBIC\20210709_1621_STEVE_DTI_009\CS_64dir',...	#2
            'CUBIC\20210723_1530_STEVE_DTI_010\CS_64dir',...	#3
            'CUBIC\20210728_1420_STEVE_DTI_011\CS_64dir',...	#4
            'CUBIC\20210729_1434_STEVE_DTI_012\CS_64dir',...	#5
            'CUBIC\20211126_1427_STEVE_DTI_013\CS_64dir',...	#6
            'CUBIC\20220117_1341_STEVE_DTI_014\CS_64dir'...     #7
            };
    case 'steve_cubic_sl'
        files={...
            'CUBIC\20210619_1014_STEVE_DTI_002\CS_sl',...	#1
            'CUBIC\20210619_1221_STEVE_DTI_006\CS_sl',...	#2
            'CUBIC\20211129_1706_STEVE_DTI_008\CS_sl',...	#3
            'CUBIC\20210709_1621_STEVE_DTI_009\CS_sl',...	#4
            'CUBIC\20210723_1530_STEVE_DTI_010\CS_sl',...	#5
            'CUBIC\20210728_1420_STEVE_DTI_011\CS_sl',...	#6
            'CUBIC\20210729_1434_STEVE_DTI_012\CS_sl',...	#7
            'CUBIC\20220117_1341_STEVE_DTI_014\CS_sl'...	#8
            };
    case 'steve_oxford_2018'
        files={
            'Oxford\20180627_O3TPR_CD01_10258\siemensBH',...        #1
            'Oxford\20180627_O3TPR_CD01_10258\siemensGate',...      #2
            'Oxford\20180627_O3TPR_CD01_10258\siemensNav',...       #3
            'Oxford\20180627_O3TPR_CD01_10258\steveNav',...         #4
            'Oxford\20180628_O3TPR_CD11_01_10275\siemensBH',...     #5
            'Oxford\20180628_O3TPR_CD11_01_10275\siemensGate',...	#6
            'Oxford\20180628_O3TPR_CD11_01_10275\siemensNav',...    #7
            'Oxford\20180628_O3TPR_CD11_01_10275\steveNav',...      #8
            'Oxford\20180629_O3TPR_C11_01_10286\siemensBH',...      #9
            'Oxford\20180629_O3TPR_C11_01_10286\siemensGate',...    #10
            'Oxford\20180629_O3TPR_C11_01_10286\siemensNav',...     #11
            'Oxford\20180629_O3TPR_C11_01_10286\steveNav'...        #12
            };
    case 'steve_oxford_2020'
        files={
            'Oxford\20200923_O3TPR_CD01_16789\siemensBH',...	#1
            'Oxford\20200923_O3TPR_CD01_16789\siemensGate',...	#2
            'Oxford\20200923_O3TPR_CD01_16789\siemensNav', ...	#3
            'Oxford\20200923_O3TPR_CD01_16789\steveNav',...     #4
            'Oxford\20201021_O3TPR_CD01_17059\siemensBH',...	#5
            'Oxford\20201021_O3TPR_CD01_17059\siemensGate',...	#6
            'Oxford\20201021_O3TPR_CD01_17059\siemensNav',...	#7
            'Oxford\20201021_O3TPR_CD01_17059\steveNav',...     #8
            };
    case 'steve_oxford_2021'
        files={
            'Oxford\20211125_O3TPR_CD01_20632_complete\siemensBH',...	#1
            'Oxford\20211125_O3TPR_CD01_20632_complete\siemensGate',...	#2
            'Oxford\20211125_O3TPR_CD01_20632_complete\siemensNav',...  #3
            'Oxford\20211125_O3TPR_CD01_20632_complete\steveNav',...    #4
            'Oxford\20211208_steveDTIAH_complete\siemensBH',...         #5
            'Oxford\20211208_steveDTIAH_complete\siemensGate',...       #6
            'Oxford\20211208_steveDTIAH_complete\siemensNav',...        #7
            'Oxford\20211208_steveDTIAH_complete\steveNav',...          #8
            'Oxford\20211222_SteveDTIFM_complete\siemensBH',...        	#9
            'Oxford\20211222_SteveDTIFM_complete\siemensGate2',...     	#10
            'Oxford\20211222_SteveDTIFM_complete\siemensNav2',...      	#11
            'Oxford\20211222_SteveDTIFM_complete\steveNav',...         	#12
            'Oxford\20220119_steveDTIhg\siemensBH',...                 	#13
            'Oxford\20220119_steveDTIhg\siemensGate',...              	#14
            'Oxford\20220119_steveDTIhg\siemensNav',...                	#15
            'Oxford\20220119_steveDTIhg\steveNav',...                 	#16
            'Oxford\20220408_SteveHM\siemensBH',...                    	#17
            'Oxford\20220408_SteveHM\siemensGate',...               	#18
            'Oxford\20220408_SteveHM\siemensNav',...                  	#19
            'Oxford\20220408_SteveHM\steveNav'...                    	#20
            };
    case 'zak'
        files={
            'PRISMA DICOMS\DTI20211021\1_',...                  #1
            'PRISMA DICOMS\DTI20211027\1_',...                  #2
            'PRISMA DICOMS\DTI20211130',...                     #3 
            'TRIO DICOMS\20210806_DTI3748',...                  #4
            'TRIO DICOMS\20210908_DTI8246_1',...                #5
            'TRIO DICOMS\20211103_DTI6259',...                  #6
            'TRIO DICOMS\20211130_DTI6281',...                  #7
            'DTI discrepancy cases\DICOMS\20210709_DTI4305',... #8
            'DTI discrepancy cases\DICOMS\20210727_DTI57',...   #9
            'DTI discrepancy cases\DICOMS\20210802_DTI7082',... #10
            'DTI discrepancy cases\DICOMS\20210819_DTI4327',... #11
            };
    otherwise
        err = 1;
end

if ~err
    cwd = files{ind};
end

end