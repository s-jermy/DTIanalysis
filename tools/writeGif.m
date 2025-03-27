%function writeGif(filename,saveDir,patID,regIm,bVal,lv,dicom)
function writeGif(dicom,nfo,contours,saveDir)

% load('gif.mat');

cardiacphases = fieldnames(dicom);

for i = 1:length(cardiacphases)
    slicelocation = fieldnames(dicom.(cardiacphases{i}));
    for j = 1:length(slicelocation)
        SliceData = dicom.(cardiacphases{i}).(slicelocation{j}).SliceData;
        SliceInfo = nfo{j}.SliceInfo;

        rec = contours.rec{j};
        epi = contours.epi{j};
        endo = contours.endo{j};
        imrangex = rec(1,1):rec(3,1);
        imrangey = rec(1,2):rec(3,2);

        B_values = arrayfun(@(x) x.B_value,SliceInfo);
        [uBVal,~,uBV2] = unique(B_values);
        
        for k = 1:length(uBVal)
            filename = ['b' num2str(uBVal(k))];
            idx = uBV2==k;
            sl = SliceData(idx);
            nf = SliceInfo(idx);
            for l = 1:length(sl)
                im = sl(l).image(imrangey,imrangex);
                regim = sl(l).regImage;
                try
                    WC = nf(l).WindowCenter;
                    WW = nf(l).WindowWidth;
                    low = WC-.5 - (WW-1)/2; high = WC-.5 + (WW-1)/2; % for mag images
                    im(im<=low) = 0; im(im>high) = 255;
                    im = ((im-(WC-.5))/(WW-1)+.5)*255;
                    regim(regim<=low) = 0; regim(regim>high) = 255;
                    regim = ((regim-(WC-.5))/(WW-1)+.5)*255;
                catch
                end
                h1 = figure(1);imagesc(uint8(im));colormap("gray");axis off;axis equal;
                h2 = figure(2);imagesc(uint8(abs(regim)));colormap("gray");axis off;axis equal;
                hold on
                plot(epi(:,1),epi(:,2),'g-');
                plot(endo(:,1),endo(:,2),'r-');
                hold off

                intim = frame2im(getframe(h1));
                [imind,cm] = rgb2ind(intim,256);
                intim = frame2im(getframe(h2));
                [imind2,cm2] = rgb2ind(intim,256);
                if l==1
                    imwrite(imind,cm,fullfile(saveDir,[filename '.gif']),'gif','Loopcount',inf,'DelayTime',0.5);
                    imwrite(imind2,cm2,fullfile(saveDir,[filename '_reg.gif']),'gif','Loopcount',inf,'DelayTime',0.5);
                else
                    imwrite(imind,cm,fullfile(saveDir,[filename '.gif']),'gif','WriteMode','append','DelayTime',0.5);
                    imwrite(imind2,cm2,fullfile(saveDir,[filename '_reg.gif']),'gif','WriteMode','append','DelayTime',0.5);
                end
            end
        end
    end
end
close all