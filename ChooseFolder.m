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
    % case 'your_tag'
    %     files={
    %         fullfile('folder','folder',...)
    %         };
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