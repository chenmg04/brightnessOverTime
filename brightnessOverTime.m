classdef brightnessOverTime < handle
    
    properties
        hMain
        infoTxt
        loadTxt
        loadAxes
        
        openList
        subList
        
        dispFig
        
        dispFigTxt
        axes1
        chSlider
        frameSlider
        
        resize
        roiTool
        stiTool
        autoFluoDetector
        fluoAnalyzer
        notes
        hgendatabase
        
        fileInfo
        openStates
        data
    end
    
    properties(Constant)
        
        mag =  [3.1 4.2 6.2 8.3 12.5 16.7 25 33.3 50 75 100,...
               150 200 300 400 600 800 1200 1600 2400 3200];
           
        screendims=get(0,'Screensize');
        
    end
    
    
        
   
    methods
        
        % Creat the main gui, including figure, infoTxt, menu, axes
        function obj = brightnessOverTime
            
            defaultsize=round(obj.screendims(3)/1366*9);
            set(0,'defaultUicontrolFontSize',defaultsize);
            
            obj.hMain    =figure('Name','BrightnessOverTime',...
                'MenuBar','none',...
                'ToolBar','none',...
                'NumberTitle','off',...
                'Resize','off',...
                'Position',[(obj.screendims(3)-512)/2 obj.screendims(4)-82 512 25],...
                'CloseRequestFcn',@obj.mainCloseRequestFcn);
            
            obj.infoTxt  =uicontrol(obj.hMain,...
                'Style','text',...
                'BackgroundColor',get(obj.hMain,'Color'),...
                'String', 'No Image Open!',...
                'HorizontalAlignment','left',...
                'Position',[8 5 350 15]);
            
            obj.loadTxt  =uicontrol(obj.hMain,...
                'Style','text',...
                'BackgroundColor',get(obj.hMain,'Color'),...
                'String', '',...
                'HorizontalAlignment','left',...
                'Position',[350 5 60 15]);
            
            obj.loadAxes =axes('Parent',obj.hMain,...
                'Units','pixels',...
                'Position',[410 5 100 15],...
                'Visible','off');
            
            obj.openList = createMenusAndToolbar(obj);
            
            obj.dispFig  = figure('Name','',...
                'MenuBar','none',...
                'ToolBar','none',...
                'NumberTitle','off',...
                'Resize','off',...
                'Position',[(obj.screendims(3)-512)/2 obj.screendims(4)-652 512 512],...
                'Visible','off',...
                'CloseRequestFcn',@obj.closeSingleImage,...
                'WindowKeyPressFcn',@obj.zoomImage);
                             
           
            obj.axes1    = axes('Parent',obj.dispFig,...
                'Units','pixels',...
                'XColor',get(obj.dispFig,'Color'),...
                'YColor',get(obj.dispFig,'Color'),...
                'XTick',[],...
                'YTick',[],...
                'Position',[0 15 512 512]);
            
            obj.chSlider = uicontrol(obj.dispFig,...
                'Style','slider',...
                'BackgroundColor',get(obj.hMain,'Color'),...
                'Min', 1,'Max',2,...
                'SliderStep',[1 1],...
                'Value',1,...
                'Position',[0 0 512 15],...
                'TooltipString','channel',...
                'Interruptible','on',...
                'Callback',@obj.channelSelection);
            
             obj.frameSlider = uicontrol(obj.dispFig,...
                'Style','slider',...
                'BackgroundColor',get(obj.hMain,'Color'),...
                'Min', 1,'Max',2,...
                'SliderStep',[1 1],...
                'Value',1,...
                'Position',[0 0 512 15],...
                'Visible','off',...
                'TooltipString','frame',...
                'Interruptible','on');
%                 'Callback',@obj.frameSelection);
                hhSlider = handle (obj.frameSlider);
                hProp= findprop(hhSlider, 'Value');
                try
                hListener = addlistener (hhSlider, hProp, 'PostSet', @obj.frameSelection);% for matlab version 2014 or older
                catch
                 hListener = handle.listener (hhSlider, hProp, 'PostSet', @obj.frameSelection);% for matlab version before 2014
                end
                setappdata ( obj.frameSlider, 'sliderListener', hListener);
            
        end
        
        % -----------------------------------------------------------------
        function [openList] = createMenusAndToolbar (obj)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % File menu
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fileMenu = uimenu(obj.hMain,...
                'Label','File',...
                'Tag','file menu');
            
            % Open item
            uimenu(fileMenu,...
                'Label','Open',...
                'Accelerator','O',...
                'Separator','off',...
                'Callback',@obj.openFromFolder);
            uimenu(fileMenu,...
                'Label','Open Batch',...
                'Separator','off',...
                'Callback',@obj.openBatchFromFolder);
            openList = uimenu(fileMenu,...
                'Label','Open List',...
                'Tag','file list');
            importMenu=uimenu(fileMenu,...
                'Label','Import',...
                'Separator','off' );
            uimenu(importMenu,...
                'Label','Tiff Stack',...
                'Separator','off',...
                'Callback',@obj.importTiffStack);  
            % Close item
            uimenu(fileMenu,...
                'Label','Close',...
                'Separator','on',...
                'Callback',@obj.closeSingleImage);
            uimenu(fileMenu,...
                'Label','Close All',...
                'Separator','off',...
                'Callback',@obj.closeAllImage);
            % Save item
            uimenu(fileMenu,...
                'Label','Save Image',...
                'Separator','on',...
                'Callback',@obj.saveImage);
            uimenu(fileMenu,...
                'Label','Save As...',...
                'Separator','off',...
                'Callback',@obj.saveImageAs);
             uimenu(fileMenu,...
                'Label','Save Imagedata...',...
                'Separator','off',...
                'Callback',@obj.saveImagedata);
            uimenu(fileMenu,...
                'Label','Save Stimulus...',...
                'Separator','off',...
                'Callback',@obj.saveStimulus);
            
            uimenu(fileMenu,...
                'Label','Export Stack',...
                'Separator','on',...
                'Callback',@obj.exportStack);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Image menu
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            imageMenu = uimenu(obj.hMain,...
                'Label','Image',...
                'Tag','image menu');
            uimenu(imageMenu,...
                'Label','Show Info',...
                'Accelerator','I',...
                'Separator','off',...
                'Callback',@obj.showImageInfo);
            %View
            viewMenu=uimenu(imageMenu,...
                'Label', 'View',...
                 'Separator','on');
           uimenu(viewMenu,...
                'Label','Original Stack',...
                'Separator','off',...
                'Callback',@obj.viewOriginalStack);  
            uimenu(viewMenu,...
                'Label','Average Frame',...
                'Separator','off',...
                'Callback',@obj.viewAverageFrame); 
            % Ajust
            ajustMenu =uimenu(imageMenu,...
                'Label','Ajust',...
                'Separator','off');
            uimenu(ajustMenu,...
                'Label','Size...',...
                'Separator','off',...
                'Callback',@obj.ajustImageSize);
            uimenu(ajustMenu,...
                'Label','Contrast...',...
                'Separator','off',...
                'Callback',@imcontrast);
            % Color
            colorMenu =uimenu(imageMenu,...
                'Label','Color',...
                'Separator','off');
            uimenu(colorMenu,...
                'Label','Jet',...
                'Separator','off',...
                'Callback',@obj.colorSet);
            uimenu(colorMenu,...
                'Label','Green',...
                'Separator','off',...
                'Callback',@obj.colorSet);
            uimenu(colorMenu,...
                'Label','Red',...
                'Separator','off',...
                'Callback',@obj.colorSet);
            uimenu(colorMenu,...
                'Label','Blue',...
                'Separator','off',...
                'Callback',@obj.colorSet);
            uimenu(colorMenu,...
                'Label','Gray',...
                'Separator','off',...
                'Callback',@obj.colorSet);
            % Zoom
            zoomMenu =uimenu(imageMenu,...
                'Label','Zoom',...
                'Separator','off');
            uimenu(zoomMenu,...
                'Label','In [+]',...
                'Separator','off',...
                'Callback',@obj.zoomIn);
            uimenu(zoomMenu,...
                'Label','Out [-]',...
                'Separator','off',...
                'Callback',@obj.zoomOut);
            uimenu(zoomMenu,...
                'Label','Original Scale',...
                'Separator','off',...
                'Callback',@obj.zoomReset);
            % Pan
            uimenu(imageMenu,...
                'Label','Pan',...
                'Separator','on',...
                'Callback',@obj.panImage);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Tool menu
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            toolMenu =uimenu(obj.hMain,...
                'Label','Tool',...
                'Tag','tool menu');
            uimenu(toolMenu,...
                'Label','Template Matching',...
                'Callback',@obj.sliceAlignment);
            % roiToolBox
            uimenu(toolMenu,...
                'Label','roiToolBox',...
                'Callback',@obj.roiToolBox);
            uimenu(toolMenu,...
                'Label','stimulus',...
                'Callback',@obj.stimulus);
             uimenu(toolMenu,...
                'Label','Notes',...
                'Callback',@obj.addnotes);
            uimenu(toolMenu,...
                'Label','Generate database',...
                'Callback',@obj.gendatabase);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Analyze menu
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            analyzeMenu =uimenu(obj.hMain,...
                'Label','Analyze',...
                'Tag','analyze menu');
            % Auto Fluorescence Detection
            uimenu(analyzeMenu,...
                'Label','Auto Fluorescence Detection',...
                'Callback',@obj.autoFluoChangeDetection);
            % Brightness Over Time
            uimenu(analyzeMenu,...
                'Label','Brightness Over Time',...
                'Callback',@obj.fluoChangeProcessor);
            
        end
        
        % Function to close main window 
        function mainCloseRequestFcn (obj,hObject,~)
            
            delete(obj.dispFig);
            
            % if roiToolBox is open, close it
            if ~isempty(obj.roiTool)
                delete(obj.roiTool.fig);
                obj.roiTool=[];
            end
            % if auto fluorescence detetor is open, close it
            if ~isempty(obj.autoFluoDetector)
                delete(obj.autoFluoDetector.fig);
                obj.autoFluoDetector=[];
            end
            
            % if auto fluorescence detetor is open, close it
            if ~isempty(obj.fluoAnalyzer)
                delete(obj.fluoAnalyzer.fig);
                obj.fluoAnalyzer=[];
            end
            
%             if ~isempty(obj.stiTool)
%                 close(stimulus);
%                 obj.stiTool=[];
%             end
            % To add more
            delete(hObject);
        end
        
        % Function to close image window/single image 
        function closeSingleImage(obj,~,~)
            
            if ~isempty (obj.roiTool)&&~isempty(get(obj.roiTool.roiList,'String'))
                
                selection=questdlg('Save the ROIs?',...
                    'ROI ToolBox',...
                    'Yes','No','Yes');
                switch selection
                    case'Yes'
                        saveRoi(obj);
                    case'No'
                        
                end
                
                set(obj.roiTool.roiList,'String',[]);
                set(obj.roiTool.roiList,'Value',1);
            end
            
            if ~isempty (obj.stiTool)
                
                if ~isempty(findobj('Name','Stimulus'))
                    close('Stimulus');
                end
                obj.stiTool=[];
            end
            
            
            fileList=obj.fileInfo;
            if isempty(fileList)
                obj.data=[];
                set(obj.dispFig,'Visible','off');
                set(obj.infoTxt,'String','No Image Open!');
                return;
            end
            
            if isfield(fileList,'fullFileName') && ~isempty(fileList.fullFileName)
                fileN=length(fileList.fullFileName);
                if fileN==1
                    delete(obj.subList);
                    obj.subList=[];
                    fileList.fullFileName=[];
                    obj.data=[];
                    set(obj.dispFig,'Visible','off');
                    set(obj.infoTxt,'String','No Image Open!');
                else
                    deleteFileName=get(obj.dispFig,'name');
                    deleteFileName=deleteFileName(1:37); % when zoom in, dispFig name is different, e.g +(100%) 
                    for i=1:fileN
                        if strfind(fileList.fullFileName{i},deleteFileName)
                            delete(obj.subList(i));
                            obj.subList(i)=[];
                            fileList.fullFileName{i}=[];
                            fileList.fullFileName   = fileList.fullFileName(~cellfun(@isempty, fileList.fullFileName));
                            break;
                        end
                    end
                    
                    processImage(obj,fileList.fullFileName{1});
                    
                end
                obj.fileInfo=fileList;
            end
            
            
                      
        end
        
        % Function to close all images 
        function closeAllImage(obj,~,~)
            
             if ~isempty (obj.roiTool)&&~isempty(get(obj.roiTool.roiList,'String'))
                
                selection=questdlg('Save the ROIs?',...
                    'ROI ToolBox',...
                    'Yes','No','Yes');
                switch selection
                    case'Yes'
                        saveRoi(obj);
                    case'No'
                        
                end
                
                set(obj.roiTool.roiList,'String',[]);
                set(obj.roiTool.roiList,'Value',1);
            end
            
            if ~isempty (obj.stiTool)
                
                if ~isempty(findobj('Name','Stimulus'))
                    close('Stimulus');
                end
                obj.stiTool=[];
            end
            
            fileList=obj.fileInfo;
            if isfield(fileList,'fullFileName') && ~isempty(fileList.fullFileName)
                delete(obj.subList);
                obj.subList=[];
                fileList.fullFileName=[];
                obj.data=[];
                set(obj.dispFig,'Visible','off');
                set(obj.infoTxt,'String','No Image Open!');
            end
            obj.fileInfo=fileList;
        end
        
        % Function to save single image in the original folder 
        function saveImage(obj,~,~)
            
            imPosition=get(obj.dispFig,'Position');
            obj.data.metadata.previewSize(1)=imPosition(3);
            obj.data.metadata.previewSize(2)=imPosition(4);
            metadata=obj.data.metadata;
            save(obj.data.info.metamat.name,'metadata');
            set(obj.infoTxt,'String','Image Was Saved!');
        end
        
        % Function to save single image as different formats in selected
        % folder
        function saveImageAs(obj,~,~)
            
            [filename, pathname] = uiputfile({'*.jpg','Jpeg(*.jpg)';'*.tif','Tiff(*.tif)';...
                                              '*.png','Png(*.png)';'*.gif','Gif(*.gif)';...
                                              '*.*','All Files(*.*)' },'Save as');
            if isequal(filename,0) || isequal(pathname,0)
                set(obj.infoTxt,'String','User pressed cancel!');
                return;
            end
            
            cd(pathname);
            image=getframe(obj.axes1);
            imwrite(image.cdata,filename);
            set(obj.infoTxt,'String',sprintf('Image saved to %s\n',fullfile(pathname, filename)));
        end
        
         function saveImagedata(obj,~,~)
             if ~exist(['raw_im_' obj.openStates.image.fileName '.mat'],'file')
                 movefile(['im_' obj.openStates.image.fileName '.mat'], ['raw_im_' obj.openStates.image.fileName '.mat']);
             end
             imagedata = obj.data.imagedata;
             if obj.data.metadata.iminfo.channel ==1
                obj.data.metadata.previewFrame =mean(imagedata(:,:,:),3);
            else
                obj.data.metadata.previewFrame{1}=mean(imagedata(:,:,1,:),4);
                obj.data.metadata.previewFrame{2}=mean(imagedata(:,:,2,:),4);
             end
            metadata=obj.data.metadata;
            save(obj.data.info.metamat.name,'metadata')
            
             save(obj.data.info.immat.name, 'imagedata');
             set(obj.infoTxt,'String','Imagedata Was Saved!');
         end
         % Function to save stimulus in the metadata
        function saveStimulus(obj,~,~)
            
            if isempty(obj.stiTool) | isempty (obj.stiTool.patternInfo)
                return;
            end
            
            obj.data.metadata.stiInfo.data=obj.stiTool.data;
            obj.data.metadata.stiInfo.baselineLength=obj.stiTool.baselineLength;
            obj.data.metadata.stiInfo.threshold=obj.stiTool.threshold;
            obj.data.metadata.stiInfo.avenum=obj.stiTool.avenum;
            obj.data.metadata.stiInfo.nSti=obj.stiTool.nSti;
            obj.data.metadata.stiInfo.startFrameN=obj.stiTool.startFrameN;
            obj.data.metadata.stiInfo.endFrameN=obj.stiTool.endFrameN;
            obj.data.metadata.stiInfo.trailInfo=obj.stiTool.trailInfo;
            obj.data.metadata.stiInfo.patternInfo=obj.stiTool.patternInfo;
            metadata=obj.data.metadata;
            save(obj.data.info.metamat.name,'metadata');
            set(obj.infoTxt,'String','Stimulus Was Saved!');
        end
        
        function exportStack (obj,~,~)
            
            [filename, pathname] = uiputfile({'*.tif','Tiff(*.tif)';...
                '*.*','All Files(*.*)' },'Export as');
            if isequal(filename,0) || isequal(pathname,0)
                set(obj.infoTxt,'string','User pressed cancel!');
                return;
            end
            
            cd(pathname);
            if ~obj.data.info.immat.loaded
                if exist(obj.data.info.immat.name,'file')
                    obj.data.imagedata=getfield(load(obj.data.info.immat.name),'imagedata');
                    obj.data.info.immat.loaded=1;
                end
            end
%             fullfilename= fullfile(pathname,filename);
%             imgdata=squeeze(obj.data.imagedata(:,:,2,:));
         
            imgdata=obj.data.imagedata; imgdata(:,:,3,:)=0;
            option.color=true;
                        saveastiff(imgdata,filename,option);
                        option.color=false;
            % %             saveastiff(squeeze(obj. data.imagedata(:,:,2,:)),[obj.openStates.image.fileName '.tif']);
%             t = Tiff(filename,'w');
%             tagstruct.ImageLength = size(imgdata,1);
%             tagstruct.ImageWidth = size(imgdata,2);
%             tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
%             tagstruct.BitsPerSample = 64;
%             tagstruct.SamplesPerPixel = 1;
%             tagstruct.RowsPerStrip = 16;
%             tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
%             tagstruct.Software = 'MATLAB';
%             t.setTag(tagstruct);
%             t.write(imgdata);
%             t.close();
            set(obj.infoTxt,'String',sprintf('ImageStack exported to %s\n',pathname));
        end
        
        % Function to zoom image by pressing keys; uparrow, zoom in;
        % downarrow zoom out; leftarrow, back to original
        function zoomImage(obj,hObject,eventdata)
            % Callback to parse keypress event data to zoom image
%             axes(obj.axes1);
            if strcmp(eventdata.Key,'uparrow')
                zoomIn(obj,hObject, eventdata)
            elseif strcmp(eventdata.Key,'downarrow')
                zoomOut(obj,hObject, eventdata)
            elseif strcmp(eventdata.Key,'leftarrow')
                zoomReset(obj,hObject, eventdata)
            end
        end
        
        % Function to zoom in image 
        function zoomIn(obj,~, ~)
            
            % Determin whether there are image open
            if isempty(obj.openStates)
                return;
            end
            
            magN     = obj.openStates.image.magN;
            zoomFactor= obj.openStates.image.zoomFactor;
            
            if magN==length(obj.mag)
                return;
            end
            
            magN = magN+1;
            magFactor=obj.mag(magN);
            
            if isfield(obj.openStates.image,'curImageSize')
                imWidth=obj.openStates.image.curImageSize(1);
                imHeight=obj.openStates.image.curImageSize(2);
            elseif isfield(obj.data.metadata,'previewSize')
                imWidth =obj.data.metadata.previewSize(1);
                imHeight=obj.data.metadata.previewSize(2);
            else
                imWidth =obj.data.metadata.iminfo.pixelsPerLine;
                imHeight=obj.data.metadata.iminfo.linesPerFrame;
            end
            
            updateImWidth =imWidth*magFactor/100;
            updateImHeight=imHeight*magFactor/100;
            
            mainFigPos=get(obj.hMain,'Position');
            figPosition=get(obj.dispFig,'Position');            
            axesPosition=get(obj.axes1, 'Position');
            
            if zoomFactor || figPosition (3)>800 || figPosition (4)>800 || updateImWidth>800 || updateImHeight>800
                axes(obj.axes1);
                zoom(obj.mag(magN)/obj.mag(magN-1));
                zoomFactor=zoomFactor+1;                
            
            elseif updateImWidth < figPosition(3)
                set(obj.dispFig,'Position',[figPosition(1) mainFigPos(2)-60-updateImHeight figPosition(3) updateImHeight+figPosition(4)-axesPosition(4)]);
                set(obj.axes1,'Position',[(figPosition(3)-updateImWidth)/2  axesPosition(2) updateImWidth updateImHeight]);
                
            elseif updateImWidth >=figPosition(3)
                set(obj.dispFig,'Position',[figPosition(1) mainFigPos(2)-60-updateImHeight updateImWidth updateImHeight+figPosition(4)-axesPosition(4)]);
                set(obj.axes1,'Position',[0 axesPosition(2) updateImWidth updateImHeight]);
                if obj.openStates.image.viewMode==1
                    set(obj.chSlider,'Position',[0 0 updateImWidth 15]);
                else
                    set(obj.chSlider,'Position',[0 15 updateImWidth 15]);
                    set(obj.frameSlider,'Position',[0 0 updateImWidth 15]);
                end

            end
            
            figName=obj.openStates.image.fileName;
            if magN==11
                updateFigName=figName;
            else
                updateFigName=[figName,' ','(',num2str(magFactor),'%',')'];
            end
            set(obj.dispFig,'Name',updateFigName);
            
            obj.openStates.image.magN = magN;
            obj.openStates.image.zoomFactor =zoomFactor;                      
            
        end
        
        % Function to zoom out image 
        function zoomOut(obj,~, ~)
            
            % Determin whether there are image open
            if isempty(obj.openStates)
                return;
            end
            
            magN     = obj.openStates.image.magN;
            zoomFactor= obj.openStates.image.zoomFactor;
            
            if magN==1
                return;
            end
            
            magN = magN-1;
            magFactor=obj.mag(magN);
            
            if isfield(obj.openStates.image,'curImageSize')
                imWidth=obj.openStates.image.curImageSize(1);
                imHeight=obj.openStates.image.curImageSize(2);
            elseif isfield(obj.data.metadata,'previewSize')
                imWidth =obj.data.metadata.previewSize(1);
                imHeight=obj.data.metadata.previewSize(2);
            else
                imWidth =obj.data.metadata.iminfo.pixelsPerLine;
                imHeight=obj.data.metadata.iminfo.linesPerFrame;
            end
            
            updateImWidth =imWidth*magFactor/100;
            updateImHeight=imHeight*magFactor/100;
            
            mainFigPos=get(obj.hMain,'Position');
            figPosition=get(obj.dispFig,'Position');
            axesPosition=get(obj.axes1, 'Position');
            
            if zoomFactor
                axes(obj.axes1);
                zoom(obj.mag(magN)/obj.mag(magN+1));
                zoomFactor=zoomFactor-1;
                
            elseif updateImWidth < 134
                set(obj.dispFig,'Position',[figPosition(1) mainFigPos(2)-60-updateImHeight 134 updateImHeight+figPosition(4)-axesPosition(4)]);
                set(obj.axes1,'Position',[(134-updateImWidth)/2 axesPosition(2) updateImWidth updateImHeight]);
                if obj.openStates.image.viewMode==1
                    set(obj.chSlider,'Position',[0 0 134 15]);
                else
                    set(obj.chSlider,'Position',[0 15 134 15]);
                    set(obj.frameSlider,'Position',[0 0 134 15]);
                 end
            elseif updateImWidth >=134
                set(obj.dispFig,'Position',[figPosition(1) mainFigPos(2)-60-updateImHeight updateImWidth updateImHeight+figPosition(4)-axesPosition(4)]);
                set(obj.axes1,'Position',[0 axesPosition(2) updateImWidth updateImHeight]);
                 if obj.openStates.image.viewMode==1
                    set(obj.chSlider,'Position',[0 0 updateImWidth 15]);
                else
                    set(obj.chSlider,'Position',[0 15 updateImWidth 15]);
                    set(obj.frameSlider,'Position',[0 0 updateImWidth 15]);
                 end
            end
            
            figName=obj.openStates.image.fileName;
            if magN==11
                updateFigName=figName;
            else
                updateFigName=[figName,' ','(',num2str(magFactor),'%',')'];
            end
            set(obj.dispFig,'Name',updateFigName);
            
            obj.openStates.image.magN = magN;
            obj.openStates.image.zoomFactor =zoomFactor;               
        end
        
        % Function to zoom reset image 
        function zoomReset(~,~, ~)
            
            
        end
        
        % Function to pan image %bugs exists, needs repair
        function panImage (obj, ~, ~)
            
            axes(obj.axes1);
            pan ON;
        end
        
        
        % Function to update image window 
        function  updateDispFig (obj)
            
            if isfield(obj.data.metadata,'previewSize')
                figWidth =obj.data.metadata.previewSize(1);
                figHeight=obj.data.metadata.previewSize(2);
            else
                figWidth =obj.data.metadata.iminfo.pixelsPerLine;
                figHeight=obj.data.metadata.iminfo.linesPerFrame;
            end
            
            % Update dispFig
            mainFigPos=get(obj.hMain,'Position');
            updateFigName=obj.openStates.image.fileName;
             set(obj.dispFig,'Name',updateFigName,'Visible','on');axis off;
            if figWidth >134 % figure width can not be smaller than 134
            set(obj.dispFig,'Position',[mainFigPos(1) mainFigPos(2)-60-figHeight figWidth figHeight+15]);
            else
                set(obj.dispFig,'Position',[mainFigPos(1) mainFigPos(2)-60-figHeight 134 figHeight+15]);
            end
            
            % Update Axes
            imPosition=get(obj.dispFig,'Position');
            if imPosition(3)>figWidth
                set(obj.axes1,'Position',[(imPosition(3)-figWidth)/2 15 figWidth figHeight]);drawnow;                
            else
                set(obj.axes1,'Position',[0 15 figWidth figHeight]);drawnow;
            end
            
            %Update chSlider
            axesPosition = get(obj.axes1, 'Position');
            if obj.data.metadata.iminfo.channel==1
%                 delete(obj.chSlider);
                set(obj.chSlider, 'Visible','off');
                set(obj.axes1,'Position',[axesPosition(1) axesPosition(2)-15 axesPosition(3) axesPosition(4)+15]);drawnow;   
                obj.data.fluoImageHandles=imagesc(obj.data.metadata.previewFrame, 'Parent',obj.axes1);axis off;drawnow;colorSelection('Green');
                obj.openStates.image.color='Green';
            else
                set(obj.chSlider, 'Visible','on');
                if imPosition(3)>figWidth
                    set(obj.chSlider,'Position',[0 0 imPosition(3) 15]);drawnow;
%                     set(obj.frameSlider,'Position',[0 0 imPosition(3) 15]);drawnow;
                else
                    set(obj.chSlider,'Position',[0 0 figWidth 15]);drawnow;
%                      set(obj.frameSlider,'Position',[0 0 figWidth 15]);drawnow;
                end
                set(obj.chSlider,'Value',2);
                obj.data.fluoImageHandles=imagesc(obj.data.metadata.previewFrame{2}, 'Parent',obj.axes1); axis off;drawnow;colorSelection('Green');
                obj.openStates.image.color{1}='Red';
                obj.openStates.image.color{2}='Green';
            end
            
            % Update frameSlider
%             frameNumber = obj.data.metadata.iminfo.framenumber;
%             set( obj. frameSlider, 'Max', frameNumber);
%             set (obj. frameSlider, 'SliderStep', [1/frameNumber 10/frameNumber]);
            
            
        end
        
        % Function to select different channels in GRB image
        function sliderSelection (obj,hObject,option) 
            
            if obj.data.metadata.iminfo.channel==2
            chSliderValue=get(obj.chSlider,'Value');
            end
            axes(obj.axes1);
%             cla ;
            
            magN     = obj.openStates.image.magN;
            zoomFactor= obj.openStates.image.zoomFactor; 
            
            hAxes1 = get(obj.axes1,'Children');
            delete (hAxes1(end));
            hAxes1(end)=[];
            nhAxes1=length(hAxes1);
            
            try
                frameSliderValue=round(get(obj.frameSlider,'Value'));
            catch
            end
            
            switch option
                case 1% for chSlider
                    if   obj.data.metadata.iminfo.channel==2
                        
                        if obj.openStates.image.viewMode==1 % view Average Frame
                            hAxes1(nhAxes1+1)=imagesc(obj.data.metadata.previewFrame{chSliderValue}, 'Parent',obj.axes1);axis off;drawnow;colorSelection(obj.openStates.image.color{chSliderValue});
                        else % view Original Stacks
                            hAxes1(nhAxes1+1)=imagesc(obj.data.imagedata(:,:,chSliderValue, frameSliderValue), 'Parent',obj.axes1);axis off;drawnow;colorSelection(obj.openStates.image.color{chSliderValue});
                        end
                        set(obj.chSlider, 'Enable', 'off');
                        figure(obj.dispFig);
                        drawnow;
                        set(obj.chSlider, 'Enable', 'on');
                    else
                        hAxes1(nhAxes1+1)=imagesc(obj.data.metadata.previewFrame, 'Parent',obj.axes1);axis off;drawnow;colorSelection(obj.openStates.image.color);
                    end
                    
                case  2 % for frameSlider
                    
                    set(obj.infoTxt,'String',frameSliderValue);
                    if ~obj.data.info.immat.loaded
                        if exist(obj.data.info.immat.name,'file')
                            obj.data.imagedata=getfield(load(obj.data.info.immat.name),'imagedata');
                            obj.data.info.immat.loaded=1;
                        end
                    end
                    if obj.data.metadata.iminfo.channel==1
                         hAxes1(nhAxes1+1)=imagesc(obj.data.imagedata(:,:,1, frameSliderValue), 'Parent',obj.axes1);axis off;drawnow;colorSelection(obj.openStates.image.color);
                    else
                        hAxes1(nhAxes1+1)=imagesc(obj.data.imagedata(:,:,chSliderValue, frameSliderValue), 'Parent',obj.axes1);axis off;drawnow;colorSelection(obj.openStates.image.color{chSliderValue});
                    end
                        set(obj.frameSlider, 'Enable', 'off');
                        figure(obj.dispFig);
                        drawnow;
                        set(obj.frameSlider, 'Enable', 'on');
            end
            
            
            if ~isfield(obj.openStates,'roi')
                if zoomFactor
                    startZoomMagN=magN-zoomFactor;
                    zoom (obj.mag(magN)/obj.mag(startZoomMagN));
                end
            end
                
            curhAxes1=get(obj.axes1,'Children'); % some problem here 
            if hAxes1(end)~=curhAxes1(end)
                set(obj.axes1,'Children',hAxes1);
            end
%             % a but needs figure out
%             if nhAxes1==0
%                 if ~isfield(obj.openStates,'roi')
%                     if zoomFactor
%                         startZoomMagN=magN-zoomFactor;
%                         zoom (obj.mag(magN)/obj.mag(startZoomMagN));
%                     end
%                 end
%             else
%                 if zoomFactor
%                     startZoomMagN=magN-zoomFactor;
%                     zoom (obj.mag(magN)/obj.mag(startZoomMagN));
%                 end
%             end
            
            % force the slider to lose focus, so to use KeyPressFcn for zoomImage. This is very much a hack.
%             set(hObject, 'Enable', 'off');
%             figure(obj.dispFig);
%             drawnow;
%             set(hObject, 'Enable', 'on');

        end
        
         function channelSelection (obj,hObject,~) 
             
              option =1;
            sliderSelection (obj,hObject,option); 
         end
        
        function frameSelection(obj,hObject, ~)
            
            option =2;
            sliderSelection (obj,hObject,option); 
        end
        
        function importTiffStack (obj, ~, ~)
           % reading tiff 
            [filename,pathname] = uigetfile ('*.tif', 'Pick a .tif file');
            cd(pathname);
            fullfilename=fullfile(pathname,filename);
            processImage (obj, fullfilename);

            
%             infoImage = imfinfo(filename);
%             mImage =infoImage(1).Width;
%             nImage =infoImage(1). Height;
%             ch = infoImage(1).SamplesPerPixel;
%             frameNumber = length(infoImage);
%             imagedata=zeros (nImage, mImage, ch, frameNumber, 'uint16');
%             
%             t= Tiff (filename, 'r');
%             for i=1:frameNumber
%                 t.setDirectory(i);
%                 imagedata(:,:,:,i)=t.read();
%             end
%             t.close;
%             % set  obj data
%             obj.data =[];
%             % imagedata
%             if ch==1
%             obj.data.imagedata = imagedata;
%             iminfo.channel=1;
%             obj.data.metadata.previewFrame =mean(imagedata(:,:,:),3);
%             else
%             obj.data.imagedata = imagedata(:,:,1:2,:);  
%              iminfo.channel=2;
%              obj.data.metadata.previewFrame{1}=mean(imagedata(:,:,1,:),4);
%              obj.data.metadata.previewFrame{2}=mean(imagedata(:,:,2,:),4);
%             end
%             % metadata
%             obj.openStates.image.fileName=filename;
%             obj.data.info.immat.loaded =1;
%             iminfo.data= infoImage(1).FileModDate;
%             iminfo.framenumber=frameNumber;
%             iminfo.pixelsPerLine=mImage;
%             iminfo.linesPerFrame=nImage;
%            obj.data.metadata.iminfo=iminfo;
%                
%             set(obj.infoTxt,'String', 'Creating Image');           
%             
%             axes(obj.axes1);
%             cla reset;
%             updateDispFig(obj);
%             
%             obj.openStates.image.curImage=obj.data.metadata.previewFrame;
%             obj.openStates.image.curImagePath=pathname;
%             obj.openStates.image.magN=11;
%             obj.openStates.image.zoomFactor=0;
%             obj.openStates.image.viewMode=1;
%        
%             set(obj.infoTxt,'string', []);
            
        end
        
        % Function to open a file from folder
        function openFromFolder (obj,~,~)
            
            filedir=uigetdir;
            
            if ~filedir
                set(obj.infoTxt,'String','No folder selected!');
                return;
            elseif isempty(strfind(filedir,'BrightnessOverTime'))&& isempty(strfind(filedir,'ZSeries'))&& isempty(strfind(filedir,'TSeries'))
                set(obj.infoTxt,'String','Not Support!');
                return;
            end
            cd(filedir);
            obj.data=[];
            processImage(obj, filedir);
%             if ~go
%                 set(obj.infoTxt,'String','Error in the folder!')
%             end
            
        end
        
        % Function to open multiple files from folder
        function openBatchFromFolder (obj,~,~)
            
%             filedir=uigetdir;
%             
%             if ~filedir
%                 set(obj.infoTxt,'String','No folder selected!');
%                 return;
%             end
%             
%             cd(filedir);
%             newFiles=dir(filedir);
%             batchdir=filedir;
%             
%             for i=1:length(newFiles)
%                 newFilesName{i}=newFiles(i).name;
%             end
%             
%             
%             mainFigPos=get(obj.hMain,'Position');
%             selectFileFig       =figure   ('Name','Multiple Select','NumberTitle','off',...
%                                              'MenuBar','none','Position',[mainFigPos(1) mainFigPos(2)-45-500 270 500],...
%                                              'Resize','off','Color','white' );
%            selectFileList   =uicontrol('Style','listbox','Value',1,'BackgroundColor','white',...
%                                              'Parent', selectFileFig,...
%                                              'Min',1, 'Max', 10,...
%                                              'Position',[2 50 266 450],...
%                                              'HorizontalAlignment','left','FontSize',10);
%              set(selectFileList,'String', newFilesName); 
%              openBatchFiles=uicontrol('Parent', selectFileFig,...
%                                                     'Style', 'pushbutton',...
%                                                     'String','Select',...
%                                                     'Position',[150 10 80 30],'FontSize',10,...
%                                                     'Callback',@selectFiles);
                                                   
           appPos=get(obj.hMain,'Position');  
           selectFileNames=selectBatchFromFolder (appPos);
           for i=1:length(selectFileNames)
               processImage(obj,selectFileNames{i});
           end
           
%            curFileN=1; 
%             while curFileN<=length(newFiles)
%                 if newFiles(curFileN).isdir==1 % is folder
%                     if ~isempty(strfind(newFiles(curFileN).name,'BrightnessOverTime')) || ~isempty(strfind(newFiles(curFileN).name,'TSeries')) %only look for BOT file folders
%                         singleFiledir=newFiles(curFileN).name;
%                         fullFileName=fullfile(batchdir,singleFiledir);
% %                         processImage(obj,fullFileName);
%                     end
%                 end
%                 
%                 curFileN=curFileN+1;
%             end
        end
        
        
        % Function to open a file from the open list
        function openListFile (obj,~,~,filedir)
            
            % determine whether the image is opened currently
            if  isequal(obj.openStates.image.curImagePath,filedir)
                %if opened, determin whether the image is same as previewFrame
                if isequal(obj.openStates.image.curImage,obj.data.metadata.previewFrame)
                    return;
                else
                    axes(obj.axes1);
                    cla; updateDispFig(obj);
                    obj.openStates.image.curImage=metadata.previewFrame;
                    obj.openStates.image.curImagePath=filedir;
                    obj.openStates.image.magN=11;
                    obj.openStates.image.zoomFactor=0;
                end
            end
            
            cd(filedir);
            axes(obj.axes1);
            cla;
            processImage(obj,filedir);
            
        end
        
        
        % Function to process image information when openning files
        function  processImage (obj, filedir)
            
            [~, fileName] = fileparts(filedir);
            obj.openStates.image.fileName=fileName;
            set(obj.infoTxt,'String', sprintf('Opening %s\n',fileName));
            
            % generate open list
            fileList=obj.fileInfo;
                      
            if isfield(fileList,'fullFileName') && ~isempty(fileList.fullFileName)
                fileN=length(fileList.fullFileName);
                i=1;
                while i<=fileN
                    if ~strcmp(fileList.fullFileName{i},filedir)
                        i=i+1;
                    else
                        break;
                    end
                    
                    if i==fileN+1;
                        fileList.fullFileName{fileN+1}=filedir;
                        obj.subList(fileN+1)=uimenu(obj.openList,'label',filedir,'position',1,'Callback',{@obj.openListFile,filedir});
                    end
                end
                
            else
                fileList.fullFileName{1}=filedir;
                obj.subList(1)=uimenu(obj.openList,'label',filedir,'position',1,'Callback',{@obj.openListFile,filedir});
                
            end
            obj.fileInfo =  fileList;         
                        
            %load image
            
            axes(obj.axes1);
            cla reset;
            try
                delete(obj.openStates.roi.curRoih);
            catch
            end
            set(obj.dispFig,'visible','off');
%             setappdata(handles.axes1,'zoomFactor',0);
            

%             obj.data.info.immat.exist=0; obj.data.info.immat.loaded=0;
%             obj.data.info.metamat.exist=0; obj.data.info.metamat.loaded=0;
            
            obj.data.info.immat.name  =fullfile(filedir, sprintf('im_%s.mat',fileName)); obj.data.info.immat.loaded=0;
            obj.data.info.metamat.name=fullfile(filedir, sprintf('meta_%s.mat',fileName));
            obj.data.info.stimmat.name=fullfile(filedir, sprintf('stim_%s.mat',fileName));
            
%             go=0;
%             
%             if ~go
%                 
%                 imagedataUP=0;
                
                if  exist(obj.data.info.immat.name,'file') && exist (obj.data.info.metamat.name,'file')
                    
%                     obj.data.info.metamat.exist=1;
                    load(obj.data.info.metamat.name);
                    
                    if isfield(metadata.iminfo, 'frameNumber')
                        f=fieldnames(metadata.iminfo);
                        f{strmatch('frameNumber', f, 'exact')}='framenumber';
                        c=struct2cell(metadata.iminfo);
                        metadata.iminfo=cell2struct(c,f);
                    end
                    
%                     obj.data.info.metamat.loaded=1;
                    obj.data.metadata=metadata;
                                        
%                     if  isfield(metadata,'previewFrame')
                        
                        updateDispFig(obj);
%                         obj.data.fluoImageHandles=imagesc(metadata.previewFrame,'parent',obj.axes1);drawnow;
%                         axis off;
%                         colormap(jet);
                        obj.openStates.image.curImage=metadata.previewFrame;
                        obj.openStates.image.curImagePath=filedir;
                        obj.openStates.image.magN=11;
                        obj.openStates.image.zoomFactor=0;
                        obj.openStates.image.viewMode =1;
%                         imagedataUP=1;
%                     else
%                         try
%                             dy=metadata.imheader.acq.linesPerFrame;
%                             dx=metadata.imheader.acq.pixelsPerLine;
%                             obj.data.fluoImageHandles=imagesc(uint16(1000*rand(dy,dx)),'parent',obj.axes1);
%                         catch
%                             
%                         end
%                     end
                    obj.data.metadata=metadata;
                else
                   openImage(obj,filedir);
                end
                
%                 if imagedataUP %show ROI
                    
                    axes(obj.axes1);
                    hold on;
                    if isfield(obj.data.metadata,'ROIdata')  && ~isempty(obj.data.metadata.ROIdata)
                        nROIs  =length(obj.data.metadata.ROIdata);
                        t=zeros(nROIs);
                        for i=1:nROIs
                            lineh=plot(obj.data.metadata.ROIdata{i}.pos(:,1),obj.data.metadata.ROIdata{i}.pos(:,2),'white', 'LineWidth',2);
                            obj.data.metadata.ROIdata{i}.linehandles=lineh;
                            t(i)=text(obj.data.metadata.ROIdata{i}.cenX,obj.data.metadata.ROIdata{i}.cenY,sprintf('%d',i),'color','white','parent',obj.axes1);
                            obj.data.metadata.ROIdata{i}.thandles=t(i);
                            hold on;
                        end
                        obj.openStates.roi.curRoih=[];
                        obj.openStates.roi.curRoiN=1;
                        roiToolBox (obj);
                        set(obj.roiTool.roiList,'string',{1:1:nROIs}, 'userdata',{1:1:nROIs});
                        set(obj.roiTool.roiList,'Value',1);
                    else
                        if ~isempty(obj.roiTool)
                            set(obj.roiTool.roiList,'string',[]);
                            set(obj.roiTool.roiList,'value',1);
                        end
                    end
                    
                if ~isempty(obj.fluoAnalyzer)
                    if isfield(obj.data.metadata,'processPara')
                        set(obj.fluoAnalyzer.filterEdit, 'String', obj.data.metadata.processPara.filter);
                        set( obj.fluoAnalyzer.baselineEdit , 'String', obj.data.metadata.processPara.baselineLength);
                        set(obj.fluoAnalyzer.traceLengthEdit, 'String', obj.data.metadata.processPara.traceLength);
                        set(obj.fluoAnalyzer.yminEdit , 'String', obj.data.metadata.processPara.ymin);
                        set(obj.fluoAnalyzer.ymaxEdit , 'String', obj.data.metadata.processPara.ymax);
                    end
                end
%                 end
                
                if ~isempty (obj.stiTool) 
                    
%                     if ~isempty(obj.stiTool.hfig)
                    if ~isempty(findobj('Name', 'Stimulus'))
                        close('Stimulus');
                    end
                    obj.stiTool=[];
                end
                
                if  exist(obj.data.info.stimmat.name,'file') 
                    
                    load(obj.data.info.stimmat.name);
                    obj.stiTool=stidata;
                end
%                 go=1;
%             end
        end
        
        % Function to open a new file
        function openImage(obj,filedir)           
             
            if isdir(filedir)
            [imagedata, metadata] = importPrairieTif(obj,filedir);
            else
                [imagedata, metadata] = openTiffStack(obj,filedir);
            end
            
            imsize=size(imagedata);
            if length(imsize)==5 % multiple sequences, Tseries
                [~, filename]=fileparts(filedir);
                imdata=imagedata;
                for i=1:imsize(5)
                    subfoldername=[filename '-sequence' num2str(i)];
                    mkdir(filedir,subfoldername);
                    
                    metadata.previewFrame{1}=mean(imdata(:,:,1,:,i),4);
                    metadata.previewFrame{2}=mean(imdata(:,:,2,:,i),4);
                    
                    obj.data.info.metamat.name=[fullfile(filedir,subfoldername) '\meta_' subfoldername '.mat'];
                    obj.data.info.immat.name=[fullfile(filedir,subfoldername) '\im_' subfoldername '.mat'];
                    
                    imagedata=squeeze(imdata(:,:,:,:,i));
                    
                    save(obj.data.info.metamat.name,'metadata');
                    set(obj.infoTxt,'string', 'Saving Imagedata');
                    drawnow;
                    save(obj.data.info.immat.name,'imagedata');
                end
                
            else
                
                if metadata.iminfo.channel ==1
                    metadata.previewFrame =mean(imagedata(:,:,:),3);
                else
                    metadata.previewFrame{1}=mean(imagedata(:,:,1,:),4);
                    metadata.previewFrame{2}=mean(imagedata(:,:,2,:),4);
                end
                %             metadata.stiInfo.sti(:,1)= 1:1:metadata.iminfo.framenumber;
                %             metadata.stiInfo.sti(:,2)= squeeze(mean((mean(imagedata(:,:,1,:),1)),2)); % average all pixel intensity in every frame in CH1 to show light stimulus
                
                save(obj.data.info.metamat.name,'metadata')
                set(obj.infoTxt,'string', 'Saving Imagedata');
                drawnow;
                save(obj.data.info.immat.name,'imagedata')
            end
%             obj.data.info.metamat.exist=1;
            obj.data.metadata=metadata;
            
            set(obj.infoTxt,'String', 'Creating Image');           
            
            axes(obj.axes1);
            cla reset;
            updateDispFig(obj);
%             obj.data.fluoImageHandles=imagesc(metadata.previewFrame,'parent',obj.axes1);
%             axis off;
%             cmap=zeros(64,3);cmap(:,2)=0:1/63:1;colormap(cmap);
            obj.openStates.image.curImage=metadata.previewFrame;
            obj.openStates.image.curImagePath=filedir;
            obj.openStates.image.magN=11;
            obj.openStates.image.zoomFactor=0;
            obj.openStates.image.viewMode=1;
            
%             set(obj.infoTxt,'string', 'Saving Imagedata');
%             drawnow;
%             save(obj.data.info.immat.name,'imagedata')
%             obj.data.info.immat.exist=1;
            obj.data.imagedata=imagedata;        
            set(obj.infoTxt,'string', []);
            
            
%             go=1;
        end
        
        %------------------------------------------------------------------
        % Function to open Prairie Tiffs, modified from import_PrairieTif.m
        % @GrassRoots Biotechnology 2011
        function [imagedata, metadata]=importPrairieTif(obj,img_full_path)
                                  
            DataType      ='uint16';         

            % If image folder or tif or XML files DNE, return empty
            if isempty(dir(img_full_path)) || numel(dir([img_full_path '/*.tif']))==0 ...
                    || numel(dir([img_full_path '/*.xml']))==0;
                imagedata = []; return;
            end
            
            % Make path *nix compatible, extract name of image
%             img_full_path = regexprep(img_full_path, '\', '/');
            [~, img_name] = fileparts(img_full_path);
                        
            % Read in metadata from xml file
            text = fileread([img_full_path '/' img_name '.xml']);
            
            date = regexp ( text, 'date="(.*?")', 'tokens', 'once');
                                             
            % Find dimensions of 5D image %
            
            % XY dimensions: Entries assumed to be the same for pixel dimensions
            xdim = str2double(regexp(text, ...
                'Key key="pixelsPerLine".*?value="(\d*)"', 'tokens','once'));
            ydim = str2double(regexp(text, ...
                'Key key="linesPerFrame".*?value="(\d*)"', 'tokens','once'));
            
            % Z axis dimension
            z_cell =  regexp(text, 'Frame relative.*?index="(\d*)"', 'tokens');
            zslice = cellfun(@(x) str2double(x{1}),z_cell);
            
            
            % T axis dimension
            t_cell =  regexp(text, 'Sequence type=.*?cycle="(\d*)"', 'tokens');
            tpoints = cellfun(@(x) str2double(x{1}),t_cell);
            if tpoints == 0; tpoints=1; end
            framenumber =length (z_cell)/length(t_cell);
            
            % Channel dimension (img names found on same line, parsed also)
            ch_img_names_cell =  regexp(text, ...
                'File channel="(\d*)".*?filename="(.*?)"', 'tokens');
            ch = cellfun(@(x) str2double(x{1}),ch_img_names_cell);
            img_names = cellfun(@(x) x{2},ch_img_names_cell, 'UniformOutput', 0);
            ch_n   = unique (ch);
            nCh    = numel(ch_n);   
            
            % Bit depth of img in filesystem
            tif_bit_depth = str2double(regexp(text, ...
                '<Key key="bitDepth".*?value="(\d*)"', 'tokens','once'));
                        
            % Parse  metadata
            set(obj.infoTxt,'string', 'Parsing Metadata');
            drawnow;
            
            frameText  = regexp (text, '<Frame .*?</Frame>', 'match', 'once');
            parNames  = regexp ( frameText, '<Key key="(\w+)".*?', 'tokens');
            parValues  = regexp ( frameText, '<Key .*?value="(.*?)"', 'tokens');
            parValues  = [parValues{:}]; parValues = [num2cell(str2double(parValues(1:2))) parValues(3) num2cell(str2double(parValues(4:end)))];
            parNames = [{'date'} {'channel'} {'frameNumber'} parNames{:}];
            parValues  = [date {nCh} {framenumber} parValues{:}];
            metadata.iminfo = cell2struct(parValues, parNames, 2);
            
            
            
%             info=regexp(text, '<Key key="(\w+)".*?value="(-*\d.*?)"', 'tokens');
%             info=vertcat(info{:});
%             
%             [~, idx]=unique(strcat(info(:,1),info(:,1),'rows'));
%             imInfo=info(sort(idx),:);
%             
%             imInfoParameterNames=(imInfo(:,1))';
%             imInfoParameterValues=([imInfo(1,2);num2cell(str2double(imInfo(2:end,2)))])';
%             
%             metadata.iminfo=cell2struct(imInfoParameterValues,imInfoParameterNames,2);
%             
%             metadata.iminfo.date                     = text (strfind(text,'date')+6:strfind(text,'date')+25);
%             metadata.iminfo.channel                  = nCh;
%             metadata.iminfo.framenumber              = max(size(regexp(text,'<Frame.*?index="([-\d\.]*?)"', 'tokens')));
                    
            % Create 1x1 mapping between img_name, channel, z slice, timepoint
            
            % Channel index
            ch_ind = ch;
                 
            
            % Zslice and timpoint index need to be repeated to match img_names elements
            flat = @(x) x(:);
            z_ind = flat(repmat(zslice, [nCh 1]));
            t_ind = flat(repmat(tpoints, [numel(unique(z_ind))*nCh 1]));
                        
            % Clear xml text form memory, not needed for final img import
            clear text;
                        
            % Initialize image specified datatype
            imagedata = zeros(ydim, xdim, nCh, ...
                max(zslice), max(tpoints), DataType);
            
            % Initialize waitebar for loading img
            waitbar_init(obj.loadAxes);
            
            % Read individual tif files into 5D img
            for n = 1:numel(img_names)
                tic;
                waitbar_fill(obj.loadAxes,n/numel(img_names));
                set(obj.infoTxt,'string', sprintf('Reading Image %d # %d / %d',str2double(img_full_path(end-3:end)), n, numel(img_names)));
                imagedata(:,:,ch_ind(n),z_ind(n),t_ind(n)) = imread([img_full_path...
                    '/' img_names{n}]) * double(intmax(DataType)/2^tif_bit_depth); %read image as 16-bit tiff file!!important to understand bit depth, the way to code color
                dt=toc;
                set(obj.loadTxt,'string',sprintf('%.1f s remaining',dt*(numel(img_names)-n)));
            end
            set(obj.loadTxt,'string',[]);
            
            % make waitbar invible after loading 
            c = get(obj.loadAxes,'Children');
            delete (c);
            set(obj.loadAxes,'visible','off');
            drawnow;
            
            % Remove extra singleton dimensions
            imagedata = squeeze(imagedata);
            
        end
        
        function [imagedata, metadata]=openTiffStack (obj,filedir)
            
            infoImage = imfinfo(filedir);
            % now only supports tiffs written by ScanImage or ImageJ
            if isfield (infoImage(1), 'ImageDescription')
                if isempty (strfind(infoImage(1).ImageDescription, 'state.software.version=3.7'))
                    software ='ScanImage';
                elseif isempty (strfind(infoImage(1).ImageDescription, 'ImageJ'))
                    software  ='ImageJ';
                else
                    software ='Others';
                end
            end
            
            
            % metadata, only import several useful from image headers
           metadata.iminfo.date = infoImage(1).FileModDate;
           frameNumber= length(infoImage); metadata.iminfo.frameNumber=frameNumber;
           mImage=infoImage(1).Width;  metadata.iminfo.pixelsPerLine=mImage;
           nImage=infoImage(1).Height;  metadata.iminfo.linesPerFrame=nImage;
           metadata.iminfo.bitDepth=infoImage(1).BitDepth;
           switch software
               case 'ScanImage'
                   ch=str2double(regexp(infoImage(1).ImageDescription, 'state.acq.numberOfChannelsSave=(\d*)', 'tokens','once'));
                   frameRate=str2double(regexp(infoImage(1).ImageDescription, 'state.acq.frameRate=(\d*)', 'tokens','once'));
               case 'ImageJ'
                   
               case 'Others'
           end
           
        
            mImage =infoImage(1).Width;
            nImage =infoImage(1). Height;
            ch = infoImage(1).SamplesPerPixel;
            frameNumber = length(infoImage);
            imagedata=zeros (nImage, mImage, ch, frameNumber, 'uint16');
            
%             t= Tiff (filename, 'r');
 t= Tiff (filedir, 'r');
            for i=1:frameNumber
                t.setDirectory(i);
                imagedata(:,:,:,i)=t.read();
            end
            t.close;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Part 2. edit image
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        
        % Function to show image info
        function showImageInfo (obj, ~, ~)
            
            if isfield(obj.data,'metadata')
                figName=obj.openStates.image.fileName;
                infoName=fieldnames(obj.data.metadata.iminfo);
                infoValue=struct2cell(obj.data.metadata.iminfo);
                infoLength=length(infoName);
                info=cell(infoLength,1);
                
                for i=1:infoLength
                    info{i}=sprintf('%s : %s',infoName{i},num2str(infoValue{i}));
                end
                
                dispFigPos            =get(obj.dispFig,'Position');
                
                figure   ('Name',figName(1,end-8:end),'NumberTitle','off','color','white',...
                                   'MenuBar','none','position',[dispFigPos(1)-240 dispFigPos(2) 220 dispFigPos(4)],'Resize','off');
                infoList=uicontrol('Style','listbox','Value',1,'BackgroundColor','white',...
                                   'Position',[1 1 219 dispFigPos(4)-1],'HorizontalAlignment','left','FontSize',10);
                set(infoList,'String',info);
                set(infoList,'Value',1);
            else
                NoImage;
                return;
            end
        end
        
        %
        function viewOriginalStack (obj,hObject, ~)
            
            if obj.openStates.image.viewMode==2
                return;
            end
            
            obj.openStates.image.viewMode=2;
            % update dispFig
            imPosition=get(obj.dispFig,'Position');
            set(obj.dispFig, 'Position', [imPosition(1) imPosition(2)-15 imPosition(3) imPosition(4)+15]);
            %update axes1
            axesPosition=get(obj.axes1, 'Position');
            set(obj.axes1, 'Position', [axesPosition(1) axesPosition(2)+15 axesPosition(3) axesPosition(4)]);
            %update sliders
            if  obj.data.metadata.iminfo.channel==2
            slider1Position=get(obj.chSlider, 'Position');
            set(obj.chSlider, 'Position', [ slider1Position(1) slider1Position(2)+15 slider1Position(3) slider1Position(4)]);
            set(obj.frameSlider, 'Position', [ slider1Position(1) 0 slider1Position(3) slider1Position(4)]);
            set(obj.frameSlider, 'Value', 1);
            else
                set(obj.frameSlider, 'Position', [ 0 0 axesPosition(3) 15]);
            end
            set(obj.frameSlider,'Visible', 'on');
            try
            frameNumber = obj.data.metadata.iminfo.framenumber;
            catch
                frameNumber = obj.data.metadata.iminfo.frameNumber;
            end
            set( obj. frameSlider, 'Max', frameNumber);
            set (obj. frameSlider, 'SliderStep', [1/frameNumber 10/frameNumber]);
            %update image
            sliderSelection (obj,hObject,2); 
        end
        
        %
        function viewAverageFrame (obj,hObject, ~)
            
             if obj.openStates.image.viewMode==1
                return;
             end
            
             obj.openStates.image.viewMode=1;
            % update dispFig
            imPosition=get(obj.dispFig,'Position');
            set(obj.dispFig, 'Position', [imPosition(1) imPosition(2)+15 imPosition(3) imPosition(4)-15]);
            %update axes1
            axesPostion=get(obj.axes1, 'Position');
            set(obj.axes1, 'Position', [axesPostion(1) axesPostion(2)-15 axesPostion(3) axesPostion(4)]);
            %update sliders
            if  obj.data.metadata.iminfo.channel==2
            slider1Position=get(obj.chSlider, 'Position');
            set(obj.chSlider, 'Position', [ slider1Position(1) slider1Position(2)-15 slider1Position(3) slider1Position(4)]);
            end
            set(obj.frameSlider,'Visible', 'off');
            %update image
            sliderSelection (obj,hObject,1); 
            
        end
        
        % Function to ajust image size
        function ajustImageSize (obj, ~, ~)
            
            if strcmp(get(obj.dispFig,'Visible'),'off')
                NoImage;
                return;
            end
            
            if isfield(obj.openStates,'curImageSize')
                imWidth=obj.openStates.image.curImageSize(1);
                imHeight=obj.openStates.image.curImageSize(2);
            elseif isfield(obj.data.metadata,'previewSize')
                imWidth =obj.data.metadata.previewSize(1);
                imHeight=obj.data.metadata.previewSize(2);
            else
                imWidth =obj.data.metadata.iminfo.pixelsPerLine;
                imHeight=obj.data.metadata.iminfo.linesPerFrame;
            end
            
            obj.resize.fig         =figure   ('Name','Resize','NumberTitle','off',...
                                              'MenuBar','none','Position',[150 150 200 140],...
                                              'Resize','off','Color','white');
            obj.resize.fixedRatio  =uicontrol('Style','checkbox','String','Constrain aspect ratio',...
                                              'Value',1,'Position',[10 40 150 20],...
                                              'HorizontalAlignment','left','Backgroundcolor','white');
                                    uicontrol('Style','text','String','Width (pixels):',...
                                              'Position',[10 95 100 20],...
                                              'HorizontalAlignment','right','Backgroundcolor','white');
                                    uicontrol('Style','text','String','Height (pixels):',...
                                              'Position',[10 70 100 20],...
                                              'HorizontalAlignment','right','Backgroundcolor','white');
            obj.resize.imWidthEdit =uicontrol('Style','edit','String',imWidth,...
                                              'Position',[120 95 50 20],...
                                              'HorizontalAlignment','left','Backgroundcolor','white');
            obj.resize.imHeightEdit=uicontrol('Style','edit','string',imHeight,...
                                              'Position',[120 70 50 20],...
                                              'HorizontalAlignment','left','backgroundcolor','white');
            set(obj.resize.imWidthEdit,'Callback',@obj.changeImWidth);
            set(obj.resize.imHeightEdit,'Callback',@obj.changeImHeight);
            obj.resize.processResize=uicontrol('Style','pushbutton','String','OK',...
                                               'Position',[120 10 50 20],...
                                               'HorizontalAlignment','center','Backgroundcolor','white',...
                                               'Callback',@obj.processResize);
        end
        
        % Function to change image width
        function changeImWidth (obj, ~, ~)
            
            if get(obj.resize.fixedRatio,'Value')
                originalImWidth =obj.data.metadata.iminfo.pixelsPerLine;
                originalImHeight=obj.data.metadata.iminfo.linesPerFrame;
                imWidth    =str2double(get(obj.resize.imWidthEdit,'String'));
                imHeight   =round(imWidth/originalImWidth*originalImHeight);
                set(obj.resize.imHeightEdit,'String',imHeight);drawnow;
            end
        end
        
        % Function to change image height
        function changeImHeight (obj, ~, ~)
            
            if get(obj.resize.fixedRatio,'Value')
                originalImWidth =obj.data.metadata.iminfo.pixelsPerLine;
                originalImHeight=obj.data.metadata.iminfo.linesPerFrame;
                imHeight    =str2double(get(obj.resize.imHeightEdit,'String'));
                imWidth     =round(imHeight/originalImHeight*originalImWidth);
                set(obj.resize.imWidthEdit,'String',imWidth);drawnow;
            end
        end
        
        % Function to process resize
        function processResize (obj, ~, ~)
            
            imWidth =str2double(get(obj.resize.imWidthEdit,'String'));
            imHeight=str2double(get(obj.resize.imHeightEdit,'String'));
            obj.openStates.image.curImageSize(1)=imWidth;
            obj.openStates.image.curImageSize(2)=imHeight;
            
            figPosition=get(obj.dispFig,'Position');
            figName=obj.openStates.image.fileName;
            
            if imWidth >600 || imHeight >600
                
                imFactor  =round(600/max(imWidth,imHeight)*100);
                diff(1:10)=obj.mag(1:10)-imFactor;
                absDiff   =abs(diff);
                minDiff   =min(absDiff);
                magN      =find(absDiff==minDiff);
                magFactor =obj.mag(magN);
                
                obj.openStates.image.magN = magN;
                obj.openStates.image.zoomFactor =0; 
                
                updatedImWidth=round(imWidth*magFactor/100);
                updatedImHeight=round(imHeight*magFactor/100);
                updateFigName=[figName,' ','(',num2str(magFactor),'%',')'];
                
                set(obj.dispFig,'Name',updateFigName,'Position',[figPosition(1) obj.screendims(4)-140-updatedImHeight updatedImWidth updatedImHeight+15]);
                set(obj.axes1,'Position',[0 15 updatedImWidth updatedImHeight]);
                set(obj.chSlider,'Position',[0 0 updatedImWidth 15]);
                
            elseif imWidth < 134
                
                obj.openStates.image.magN = 11;
                obj.openStates.image.zoomFactor =0;
                
                set(obj.dispFig,'Name',figName,'Position',[figPosition(1) obj.screendims(4)-140-imHeight 134 imHeight+15]);
                set(obj.axes1,'Position',[(134-imWidth)/2 15 imWidth imHeight]);
                set(obj.chSlider,'Position',[0 0 134 15]);
            else    
                
                obj.openStates.image.magN = 11;
                obj.openStates.image.zoomFactor =0;
                
                set(obj.dispFig,'Position',[figPosition(1) obj.screendims(4)-140-imHeight imWidth imHeight]);
                set(obj.axes1,'Position',[0 15 imWidth imHeight]);
                set(obj.chSlider,'Position',[0 0 imWidth 15]);
                
            end
            figure(obj.dispFig);
            close('Resize');
        end
        
        % Function to set colors 
        function colorSet (obj, hObject, ~)
            
            label = get( hObject, 'Label' );
            axes(obj.axes1);
            colorSelection(label);
            
            chSliderValue=get(obj.chSlider,'Value');
            obj.openStates.image.color{chSliderValue}=label;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Part 3. Tools
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        % slice Alignment
        function sliceAlignment (obj, ~, ~)
        
            set(obj.infoTxt,'String','Please select a rectangle region!');
            axes(obj.axes1);
            selectedRegion = imrect;
            selectedRegionPosition = round(selectedRegion.getPosition);
            
            chSliderValue=get(obj.chSlider,'Value');
            frameSliderValue=round(get(obj.frameSlider,'Value'));
            
            % load imagedata
            if ~obj.data.info.immat.loaded
                if exist(obj.data.info.immat.name,'file')
                    obj.data.imagedata=getfield(load(obj.data.info.immat.name),'imagedata');
                    obj.data.info.immat.loaded=1;
                end
            end
            
            template = obj.data.imagedata( selectedRegionPosition(2)+1:selectedRegionPosition(2)+selectedRegionPosition(4),...
                                                            selectedRegionPosition(1)+1:selectedRegionPosition(1)+selectedRegionPosition(3),...
                                                            chSliderValue, frameSliderValue);
             imsize = size(obj.data.imagedata);
             corImagedata= zeros( imsize(1), imsize(2),imsize(3),imsize(4), 'uint16');
             waitbar_init(obj.loadAxes);
             
             for i=1:imsize(4)
                 waitbar_fill(obj.loadAxes,i/imsize(4));
                 set(obj.infoTxt,'String', sprintf('Correcting Image # %d / %d',i, imsize(4)));
                 c=normxcorr2( template,obj.data.imagedata(:,:,chSliderValue, i));
                 [ypeak, xpeak] = find (c==max(c(:)));
                 yoffSet = ypeak-size (template, 1);
                 xoffSet = xpeak-size (template, 2);
                 ycor = selectedRegionPosition(2)-yoffSet;
                 xcor = selectedRegionPosition(1)-xoffSet;
                 set(obj.loadTxt,'String',sprintf('X: %d, Y: %d',xcor, ycor));
                 if ycor>0 && xcor>0
                 corImagedata(ycor+1: imsize(1), xcor+1:imsize(2), chSliderValue, i)=obj.data.imagedata(1: imsize(1)-ycor, 1:imsize(2)-xcor, chSliderValue, i);
                 elseif ycor<=0 &&xcor<=0
                 corImagedata(1: imsize(1)-abs(ycor), 1:imsize(2)-abs(xcor), chSliderValue, i)=obj.data.imagedata(abs(ycor)+1: imsize(1), abs(xcor)+1:imsize(2), chSliderValue, i);
                 elseif ycor>0 && xcor<=0
                  corImagedata(ycor+1: imsize(1), 1:imsize(2)-abs(xcor), chSliderValue, i)=obj.data.imagedata(1: imsize(1)-ycor, abs(xcor)+1:imsize(2), chSliderValue, i);
                 else
                  corImagedata(1: imsize(1)-abs(ycor), xcor+1:imsize(2), chSliderValue, i)=obj.data.imagedata(abs(ycor)+1: imsize(1), 1:imsize(2)-xcor, chSliderValue, i);  
                 end
                 
             end         
            
            set(obj.loadTxt,'string',[]);
            
            % make waitbar invible after loading 
            c = get(obj.loadAxes,'Children');
            delete (c);
            set(obj.loadAxes,'visible','off');
            drawnow;
            
             selectedRegion.delete;
             obj.data.imagedata=corImagedata;
             set(obj.infoTxt,'String','Correction was done!');
             
        end
        
        % roiToolBox
        function roiToolBox (obj, ~, ~)
            
            if isempty(obj.roiTool)
                initRoiToolBox (obj)
            end
        end
        
        % initialize gui for roiToolBox
        function initRoiToolBox (obj)
            
            dispFigPos            =get(obj.dispFig,'Position');
            
            obj.roiTool.fig       =figure   ('Name','ROI ToolBox','NumberTitle','off',...
                                             'MenuBar','none','Position',[dispFigPos(1)+dispFigPos(3)+20 dispFigPos(2)+dispFigPos(4)-250 160 250],...
                                             'Resize','off','Color','white',... 
                                             'CloseRequestFcn',@obj.roiToolBoxClose);
                                         
%             setappdata(obj.roiToolBox,'handles',obj.roiToolBoxh);
            obj.roiTool.roiList   =uicontrol('Style','listbox','Value',1,'BackgroundColor','white',...
                                             'Position',[1 1 80 249],...
                                             'HorizontalAlignment','left',...
                                             'Callback',@obj.roiList);
            obj.roiTool.addRoi    =uicontrol('Style','pushbutton','String','Add',...
                                             'Position',[81 220 79 30],...
                                             'Callback',@obj.addRoi);
            obj.roiTool.updateRoi =uicontrol('Style','pushbutton','String','Update',...
                                             'Position',[81 190 79 30],...
                                             'Callback',@obj.updateRoi);
            obj.roiTool.deletRoi  =uicontrol('Style','pushbutton','String','Delete',...
                                             'Position',[81 160 79 30],...
                                             'Callback',@obj.deleteRoi);
            obj.roiTool.importRoi =uicontrol('Style','pushbutton','String','Import',...
                                             'Position',[81 130 79 30],...
                                             'Callback',@obj.importRoi);
            obj.roiTool.saveRoi   =uicontrol('Style','pushbutton','String','Save',...
                                             'Position',[81 100 79 30],...
                                             'Callback',@obj.saveRoi);
            obj.roiTool.measureRoi=uicontrol('Style','pushbutton','String','Measure',...
                                             'Position',[81 70 79 30],...
                                             'Callback',@obj.measureRoi);
            obj.roiTool.showAllRoi=uicontrol('Style','checkbox','String','ShowAll',...
                                             'Position',[81 35 77 25],'Backgroundcolor','white');
            obj.roiTool.labelRoi  =uicontrol('Style','checkbox','String','Labels',...
                                             'Position',[81 10 77 25],'Backgroundcolor','white',...
                                             'Callback',@obj.labelRoi );
        end
        
        % Functio to select in roiList
        function roiList (obj, hObject, ~)
            
           
            % handles.roiList=getappdata(handles.roiToolBox,'handles');
%             obj.roiList=guidata(obj.axes1);
            if ~isfield(obj.data,'metadata') || ~isfield(obj.data.metadata,'ROIdata')  || isempty(obj.data.metadata.ROIdata)
                NoROI;
                return;
            end
            
            axes(obj.axes1);
            hold on;
            nROIs  =length(obj.data.metadata.ROIdata);
            preSelectROI  =obj.openStates.roi.curRoih;
            preSelectIndex=obj.openStates.roi.curRoiN;
            
            if preSelectIndex ~=0
                if nROIs==1 %only one ROI
%                   return;
                else
                    if ~isempty(preSelectROI)
                    delete(preSelectROI);
                    lineh=plot(obj.data.metadata.ROIdata{preSelectIndex}.pos(:,1),obj.data.metadata.ROIdata{preSelectIndex}.pos(:,2),'white', 'LineWidth',2);
                    obj.data.metadata.ROIdata{preSelectIndex}.linehandles=lineh;
                    end
                end
            end
            
            index=get(hObject,'Value');
            delete(obj.data.metadata.ROIdata{index}.linehandles);
            selectROI=impoly(obj.axes1,obj.data.metadata.ROIdata{index}.pos);
            obj.openStates.roi.curRoih=selectROI;
            obj.openStates.roi.curRoiN=index;
        end
        
        % Function to add new roi
        function addRoi (obj,~,~)
            
            if isempty(obj.openStates)
                
                choice=questdlg('There are no images open! Would you like to open now?',...
                    'No Image',...
                    'No', 'Yes','Yes');
                switch choice
                    case 'No'
                        return;
                    case 'Yes'
                        openFromFolder (obj);
                end
                return;
            end
            
            axes(obj.axes1);
            if isfield (obj.openStates,'roi')
                preSelectROI  =obj.openStates.roi.curRoih;
                preSelectIndex=obj.openStates.roi.curRoiN;
            else
                preSelectROI=[];
                preSelectIndex=[];
            end
            hold on;
            
            % check whether there are ROIs already, and show these ROIs
            if isfield(obj.data.metadata,'ROIdata') &&~isempty(obj.data.metadata.ROIdata)
                nROIs  =length(obj.data.metadata.ROIdata);
                curROIn=nROIs+1;
                
                if ~isempty(preSelectIndex)
                    delete(preSelectROI);
                    lineh=plot(obj.data.metadata.ROIdata{preSelectIndex}.pos(:,1),obj.data.metadata.ROIdata{preSelectIndex}.pos(:,2),'white', 'LineWidth',2);
                    obj.data.metadata.ROIdata{preSelectIndex}.linehandles=lineh;
%                     setappdata(handles.roiList,'handles',[]);
%                     setappdata(handles.roiList,'index',[]);
                end
                
            else
                curROIn=1;
            end
            
            % draw new ROI
            
            newROIPolyh=impoly;
            newROIdata=getPosition(newROIPolyh);
            % ROI just added was selected by defaut! This is different than selection from ROIList
            obj.openStates.roi.curRoih=newROIPolyh;
            obj.openStates.roi.curRoiN=curROIn;
            
            % Determine the center of the polygon and label ROI
            x=(min(newROIdata(:,1))+max(newROIdata(:,1)))/2;
            y=(min(newROIdata(:,2))+max(newROIdata(:,2)))/2;
            t(curROIn)=text(x,y,sprintf('%d',curROIn),'color','white','Parent',obj.axes1);
            set(obj.roiTool.roiList,'String',{1:1:curROIn}, 'Userdata',{1:1:curROIn});
            set(obj.roiTool.roiList,'Value', curROIn);           
            
            newROIdata=[newROIdata;newROIdata(1,:)];
            obj.data.metadata.ROIdata{curROIn}.pos=newROIdata;
            obj.data.metadata.ROIdata{curROIn}.cenX=x;
            obj.data.metadata.ROIdata{curROIn}.cenY=y;
            obj.data.metadata.ROIdata{curROIn}.ROIhandles=newROIPolyh;
            obj.data.metadata.ROIdata{curROIn}.thandles=t(curROIn);
        end
        
        % Function to update roi
        function updateRoi (obj, ~, ~)
            
            selectIndex=obj.openStates.roi.curRoiN;
            
            if ~isfield(obj.data,'metadata')
                NoImage;
                return;
            elseif ~isfield(obj.data.metadata,'ROIdata') || isempty(obj.data.metadata.ROIdata)
                NoROI;
                return;
            elseif isempty(selectIndex)
                NoROI_Selected
                return;
            end
            axes(obj.axes1);
            hold on;
            
            selectROI=obj.openStates.roi.curRoih;
            updatePos=getPosition(selectROI);
            updateROI=selectROI;
            
            x=(min(updatePos(:,1))+max(updatePos(:,1)))/2;
            y=(min(updatePos(:,2))+max(updatePos(:,2)))/2;
            delete(obj.data.metadata.ROIdata{selectIndex}.thandles);
            t(selectIndex)=text(x,y,sprintf('%d',selectIndex),'color','white','Parent',obj.axes1);
            
            updatePos=[updatePos;updatePos(1,:)];
            obj.data.metadata.ROIdata{selectIndex}.pos=updatePos;
            obj.data.metadata.ROIdata{selectIndex}.cenX=x;
            obj.data.metadata.ROIdata{selectIndex}.cenY=y;
            obj.data.metadata.ROIdata{selectIndex}.ROIhandles=updateROI;
            obj.data.metadata.ROIdata{selectIndex}.thandles=t(selectIndex);
            
            if isfield(obj.data.metadata.ROIdata{selectIndex},'linehandles')
                obj.data.metadata.ROIdata{selectIndex}=rmfield(obj.data.metadata.ROIdata{selectIndex},'linehandles');
            end
            
            if isfield(obj.data.metadata.ROIdata{selectIndex},'intensity')
                obj.data.metadata.ROIdata{selectIndex}=rmfield(obj.data.metadata.ROIdata{selectIndex},'intensity');
            end

            obj.openStates.roi.curRoiN=selectIndex;
            obj.openStates.roi.curRoih=updateROI;
        end
        
        % Function to delete roi
        function deleteRoi (obj, ~, ~)
            
            selectIndex=obj.openStates.roi.curRoiN;
            
            if ~isfield(obj.data,'metadata')
                NoImage;
                return;
            elseif ~isfield(obj.data.metadata,'ROIdata') || isempty(obj.data.metadata.ROIdata)
                NoROI;
                return;
            elseif isempty(selectIndex)
                if strcmp(DeleteAll,'No')
                    return;
                else
                    axes(obj.axes1);
                    cla;
                    chSliderValue=get(obj.chSlider,'Value');
                    
                    hAxes1 = get(obj.axes1,'Children');
                    nhAxes1=length(hAxes1);            
                    
                    if isequal(obj.openStates.image.curImage,obj.data.metadata.previewFrame)
                        hAxes1(nhAxes1+1)=imagesc(obj.openStates.image.curImage{chSliderValue},'Parent',obj.axes1);colorSelection(obj.openStates.image.color{chSliderValue});
                    else
                        hAxes1(nhAxes1+1)=imagesc(obj.data.curImage,'Parent',obj.axes1);colormap(gray);
                    end
                    set(obj.axes1,'Children',hAxes1);
                    
                    obj.data.metadata=rmfield(obj.data.metadata,'ROIdata');
                    set(obj.roiTool.roiList,'String',[]);
                    set(obj.roiTool.roiList,'Value',1);
                    return;
                end
            end
            
%             hold on;
            nROIs  =length(obj.data.metadata.ROIdata);
            
            % delete selected ROI
            selectROI=obj.openStates.roi.curRoih;
            delete(selectROI);
            
            % delete text for selected ROI
            delete(obj.data.metadata.ROIdata{selectIndex}.thandles);
            obj.data.metadata.ROIdata{selectIndex}=[];
            obj.data.metadata.ROIdata = obj.data.metadata.ROIdata(~cellfun(@isempty, obj.data.metadata.ROIdata));
            
            leftnROIs=nROIs-1;
            if leftnROIs==0
                set(obj.roiTool.roiList,'String',[]);
            else  
                t=zeros(leftnROIs);
                for i=1:leftnROIs
                    delete(obj.data.metadata.ROIdata{i}.thandles)
                    t(i)=text(obj.data.metadata.ROIdata{i}.cenX,obj.data.metadata.ROIdata{i}.cenY,sprintf('%d',i),'Color','white','Parent',obj.axes1);
                    obj.data.metadata.ROIdata{i}.thandles=t(i);
                end
                set(obj.roiTool.roiList,'String',{1:1:leftnROIs}, 'Userdata',{1:1:leftnROIs});
            end
            set(obj.roiTool.roiList,'Value',1); 
            obj.openStates.roi.curRoiN=[];
            obj.openStates.roi.curRoih=[];

        end
        
        % Function to import roi
        function importRoi (obj, ~, ~ )
                        
            if isfield(obj.data,'metadata')
                
                filedir=uigetdir;
                cd(filedir);
                metadata=fullfile(filedir, sprintf('meta_%s.mat',shortfile(filedir)));
                load(metadata);
                
                axes(obj.axes1);
                hold on;
                if isfield(metadata,'ROIdata') && ~isempty(metadata.ROIdata)
                    obj.data.metadata.ROIdata=metadata.ROIdata;
                    nROIs  =length(obj.data.metadata.ROIdata); 
                    t=zeros(nROIs);
                    for i=1:nROIs
                        lineh=plot(obj.data.metadata.ROIdata{i}.pos(:,1),obj.data.metadata.ROIdata{i}.pos(:,2),'white', 'LineWidth',2);
                        obj.data.metadata.ROIdata{i}.linehandles=lineh;
                        t(i)=text(obj.data.metadata.ROIdata{i}.cenX,obj.data.metadata.ROIdata{i}.cenY,sprintf('%d',i),'color','white','parent',obj.axes1);
                        obj.data.metadata.ROIdata{i}.thandles=t(i);
                        hold on;
                    end
                    obj.openStates.roi.curRoih=[];
                    obj.openStates.roi.curRoiN=1;
                    %                         roiToolBox (obj);
                    set(obj.roiTool.roiList,'string',{1:1:nROIs}, 'userdata',{1:1:nROIs});
                    set(obj.roiTool.roiList,'Value',1);
                    
                    
                    
                    %                 if isfield(metadata,'ROIdata') && ~isempty(metadata.ROIdata)
                    %                     obj.data.metadata.ROIdata=metadata.ROIdata;
                    %                     nROIs  =length(obj.data.metadata.ROIdata);
                    %                     t=zeros(nROIs);
                    %                     for i=1:nROIs
                    %                         lineh=plot(obj.data.metadata.ROIdata{i}.pos(:,1),obj.data.metadata.ROIdata{i}.pos(:,2),'white', 'LineWidth',2);
                    %                         obj.data.metadata.ROIdata{i}.linehandles=lineh;
                    %                         t(i)=text(metadata.ROIdata{i}.cenX,metadata.ROIdata{i}.cenY,sprintf('%d',i),'color','white','parent',obj.axes1);
                    %                         obj.data.metadata.ROIdata{i}.thandles=t(i);
                    %                         hold on;
                    %                     end
                    %                     set(obj.roiTool.roiList,'string',{1:1:nROIs}, 'Userdata',{1:1:nROIs});
                    %                     set(obj.roiTool.roiList,'Value',1);
                    
                else
                    NoROI;
                    return;
                end
                
            else
                NoImage;
                return;
            end
        end
        
        % Function to save roi
        function saveRoi (obj, ~, ~)
            
            metadata=obj.data.metadata;
            nROIs  =length(metadata.ROIdata); %only save ROI info, no fluo intensity.
            for i=1:nROIs
                if isfield(metadata.ROIdata{i},'intensity')
                    metadata.ROIdata{i}=rmfield(metadata.ROIdata{i},'intensity');                   
                end
                
                if isfield(metadata.ROIdata{i},'linehandles')
                    metadata.ROIdata{i}=rmfield(metadata.ROIdata{i},'linehandles');                   
                end
                
                if isfield(metadata.ROIdata{i},'ROIhandles')
                    metadata.ROIdata{i}=rmfield(metadata.ROIdata{i},'ROIhandles');
                end
                
                 if isfield(metadata.ROIdata{i},'thandles')
                     metadata.ROIdata{i}=rmfield(metadata.ROIdata{i},'thandles');
                end
            end
            
            save(obj.data.info.metamat.name, 'metadata');
            set(obj.infoTxt,'string','ROIs Saved!');
        end
        
        % Function to measure the intensity of roi
        function measureRoi (obj, ~, ~)
            
        
            nFrames  =obj.data.metadata.iminfo.framenumber;
           
            frameRate=obj.data.metadata.iminfo.framePeriod;
            fluoTime =frameRate*(1:1:nFrames);
            
            selectIndex=obj.openStates.roi.curRoiN;
            if isempty(selectIndex)
                NoROI_Selected;
                return;
            end
            if obj.data.metadata.iminfo.channel==1
                chN=1;
            else
                chN=get(obj.chSlider,'Value');
            end
            [intensityAve]=getintensity(obj,selectIndex,chN);
            
            figure(200);
            if chN==1
                plot(fluoTime,intensityAve,'Color','b');
            else
                plot(fluoTime,intensityAve,'Color','k');
            end
            hold on;
        end
        
        % Function to calculate the intensity
        function [intensityAve]=getintensity(obj,ROIn,chN)
            
            if isfield(obj.data.metadata.ROIdata{ROIn},'intensity')&&...
                    length(obj.data.metadata.ROIdata{ROIn}.intensity)>=chN &&...
                    ~isempty (obj.data.metadata.ROIdata{ROIn}.intensity {chN})
                intensityAve=obj.data.metadata.ROIdata{ROIn}.intensity{chN};
            else
                try
                nFrames  =obj.data.metadata.iminfo.framenumber;
                catch
                    nFrames  =obj.data.metadata.iminfo.frameNumber;
                end
                if ~obj.data.info.immat.loaded
                    if exist(obj.data.info.immat.name,'file')
                        obj.data.imagedata=getfield(load(obj.data.info.immat.name),'imagedata');
                        obj.data.info.immat.loaded=1;
                    end
                end
                
                selectROI=obj.openStates.roi.curRoih;% problem here
                if ~isempty(selectROI)
                    curROI=selectROI;
                    mask=createMask(curROI);
                else
                    curROI=impoly(obj.axes1,obj.data.metadata.ROIdata{ROIn}.pos);
                    mask=createMask(curROI);
                    delete(curROI);
                end
                pmask=find(mask);
                npmask=max(size(pmask));
                intensityAve=zeros(nFrames,1);
                
                for i=1:nFrames
                    a=squeeze(obj.data.imagedata(:,:,chN,i));
                    intensityAve(i)=sum(a(pmask))/npmask;
                end
                obj.data.metadata.ROIdata{ROIn}.intensity{chN}=intensityAve;
            end
        end
        
        
        function labelRoi(obj,hObject,~)
            
             if isempty(obj.openStates) % no image open 
                return;
            end
            
            axes(obj.axes1);
            if isfield (obj.openStates,'roi')
                try
                    ROIdata=obj.data.metadata.ROIdata;
                    nROIs  =length(ROIdata);
                catch
                end
   
            end
           
            if get(hObject, 'Value')
                
                for i=1:nROIs
                    obj.data.metadata.ROIdata{i}.thandles=text(obj.data.metadata.ROIdata{i}.cenX,obj.data.metadata.ROIdata{i}.cenY,sprintf('%d',i),'color','white','Parent',obj.axes1);
                end
            else
                for i=1:nROIs
                    delete( obj.data.metadata.ROIdata{i}.thandles);
                    obj.data.metadata.ROIdata{i}=rmfield(obj.data.metadata.ROIdata{i},'thandles');
                end
            end
                
            
            
        end
        % Function to close roiToolBox window
        function roiToolBoxClose (obj, ~, ~)
            
%             handles.roiList=guidata(handles.axes1);
            
            if ~isempty(get(obj.roiTool.roiList,'String'))
                
                selection=questdlg('Save the ROIs?',...
                    'ROI ToolBox',...
                    'Yes','No','Yes');
                switch selection
                    case'Yes'
                        saveRoi(obj);
                        
                    case'No'
                        
                end
                
                axes(obj.axes1);
                 hAxes1 = get(obj.axes1,'Children');
                  nhAxes1=length(hAxes1);
                  delete(hAxes1(1:nhAxes1-1));
                 updateHAxes1=hAxes1(end);
                 set(obj.axes1,'Children',updateHAxes1);
                 
%                 cla;
%                 if isequal(obj.openStates.image.curImage,obj.data.metadata.previewFrame)
%                     imagesc(obj.openStates.image.curImage{2},'Parent',obj.axes1);colormap(jet);
%                 else
%                     imagesc(obj.openStates.image.curImage{2},'Parent',obj.axes1);colormap(gray);
%                 end
                obj.data.metadata=rmfield(obj.data.metadata,'ROIdata');
                
            end
            
            delete(obj.roiTool.fig);
            obj.roiTool=[];
        
        end
        
        % stimulus
        function stimulus (obj, ~, ~)
            
            % No image open
            if isempty(obj.data)
                set(obj.infoTxt,'String','Please Open An Image First!');
                return;
            end
            
            % two versions, compare date first
            y=str2double(regexp(obj.data.metadata.iminfo.date,'.*/.*/(\d*)','tokens','once'));
            m=str2double(regexp(obj.data.metadata.iminfo.date,'(\d)*/.*','tokens','once'));
            d=str2double(regexp(obj.data.metadata.iminfo.date,'.*/(\d)*/.*','tokens','once'));
            a=datecmp(y,m,d,2015,12,31);
            
            if a>=0 % version before 7/31/2015
            %Image open, did not open stiTool for this image
            if isempty (obj.stiTool)
                % Stimulus already processed, and saved in the metadata
                if isfield(obj.data.metadata,'stiInfo')
%                     obj.stiTool=stimulus(obj.data.metadata.stiInfo);
                    obj.stiTool=stim(obj.data.metadata.stiInfo);
                % First time to process the stimulus related to the image
                else
                    lastSti=[];
                    if isfield(obj.openStates,'sti')
                        lastSti=obj.openStates.sti;
                    end
                    
                    if obj.data.metadata.iminfo.channel==2
%                     choice=questdlg('Would you like to open stimulus from the red channel?',...
%                         'Open Stimulus',...
%                         'Yes','No','Yes');
%                     switch choice
%                         case 'Yes' % Chose stimulus from the red channel
                            if ~obj.data.info.immat.loaded
                                if exist(obj.data.info.immat.name,'file')
                                    obj.data.imagedata=getfield(load(obj.data.info.immat.name),'imagedata');
                                    obj.data.info.immat.loaded=1;
                                end
                            end
                            stidata=squeeze(mean((mean(obj.data.imagedata(:,:,1,:),1)),2));
%                            obj.stiTool=stimulus(stidata);
                            obj.stiTool=stim(stidata,lastSti);
%                         case 'No'  % Import stimulus from other files
%                             obj.stiTool=stimulius();
                    else
                            obj.stiTool=stim();
                    end
                end
            else
                %Image open, opened stiTool for this image
                if ~isfield(obj.stiTool, 'h') || isempty(obj.stiTool.h.fig)
                    
%                     obj.stiTool=stimulus(obj.stiTool);
                      obj.stiTool=stim(obj.stiTool);
                else
                    return;
                end
            end
          
            waitfor(obj.stiTool.h.fig);
            try
                obj.openStates.sti.threshold=obj.stiTool.threshold;
                obj.openStates.sti.patternInfo=obj.stiTool.patternInfo;
                obj.openStates.sti.paraInfo =obj.stiTool.paraInfo;
            catch
            end
            else
                
            end
            
            
           
%             if ~isempty(obj.stiTool)
%                 return;
%             end
%             
%             if isempty (obj.openStates)
%                 set(obj.infoTxt,'String','No Image Open!')
%                 return;    
%             end
%             
%             if ~isfield (obj.data.metadata,'stidata')
%                 
%                 choice=questdlg('Where would you like to open stimulus from?',...
%                     'Open Stimulus',...
%                     'File','Red Channel','Red Channel');
%                 switch choice
%                     case 'File',
%                         [filename, pathname] = uigetfile('*.m', 'Pick a file');
%                         if isequal(filename,0) || isequal(pathname,0)
%                             set(obj.infoTxt,'String','User pressed cancel');
%                             return;
%                         else
%                             set(obj.infoTxt,'String',printf('User selected %s', fullfile(pathname, filename)));
%                         end
%                         
%                         stiRaw=fullfile(pathname, filename);
%                         load(stiRaw); obj.data.metadata.stidata.stiRaw=stiRaw;
%                     case 'Red Channel'
%                         obj.data.metadata.stidata.stiRaw=squeeze(mean((mean(obj.data.imagedata(:,:,1,:),1)),2));
%                         
%                 end
%             end
        end
        
        function addnotes(obj, ~,~)
            
%             load(obj.data.info.metamat.name);
%             obj.data.metadata=metadata;
            if isfield(obj.data,'metadata')
                obj.data.metadata.notes=addnotes(obj.data.metadata);
            else
                return;
            end
        end
        
        function gendatabase(obj, ~,~)
            obj.hgendatabase=generateDatabase;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Part 4. Analyze
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        
        % Auto Fluorescence Detection figure
        function autoFluoChangeDetection (obj, ~, ~)
            
            if isempty(obj.autoFluoDetector)
                initAutoFluoDetector (obj)
            end
        end
        
        function initAutoFluoDetector (obj)
                  
            
            obj.autoFluoDetector.fig  =figure   ('Name','Auto Fluorescence Detector','NumberTitle','off',...
                'MenuBar','none',...
                'Resize','off','Color','white',...
                'CloseRequestFcn',@obj.autoFluoDetectionClose);
            try 
                roiFigPos=get(obj.roiTool.fig,'Position');
                set(obj.autoFluoDetector.fig,'Position',[roiFigPos(1) roiFigPos(2)-150 160 110]);
            catch
                dispFigPos            =get(obj.dispFig,'Position');
                set(obj.autoFluoDetector.fig,'Position',[dispFigPos(1)+dispFigPos(3)+20 dispFigPos(2)+dispFigPos(4)-400 160 110]);
            end
            
            %Creat uicontrol
            obj.autoFluoDetector.para               =uipanel('Title','',...
               'FontSize',9,...
               'BackgroundColor','white',...
               'Units','pixels',...
               'Position',[2 40 158 60],...
               'Parent',  obj.autoFluoDetector.fig);
            obj.autoFluoDetector.withSti            =uicontrol('Style','radiobutton',...
                'String','With Sti',...
                'FontSize',12,...
                'BackgroundColor','white',...
                'Position',[1 35 70 20],...
                'Value',1,...
                'Parent',  obj.autoFluoDetector.para,...
                'Callback',@obj.withSti);
            obj.autoFluoDetector.withoutSti         =uicontrol('Style','radiobutton',...
                'String','Without',...
                'FontSize',12,...
                'BackgroundColor','white',...
                'Position',[70 35 70 20],...
                'Parent',  obj.autoFluoDetector.para,...
                'Callback',@obj.withoutSti);
            obj.autoFluoDetector.onResp            =uicontrol('Style','radiobutton',...
                'String','ON',...
                'FontSize',12,...
                'BackgroundColor','white',...
                'Position',[1 5 60 20],...
                'Value',1,...
                'Parent',  obj.autoFluoDetector.para,...
                'Callback',@obj.onResp);
            obj.autoFluoDetector.offResp         =uicontrol('Style','radiobutton',...
                'String','OFF',...
                'FontSize',12,...
                'BackgroundColor','white',...
                'Position',[41 5 55 20],...
                'Parent',  obj.autoFluoDetector.para,...
                'Callback',@obj.offResp);
            obj.autoFluoDetector.onoffResp         =uicontrol('Style','radiobutton',...
                'String','ONOFF',...
                'FontSize',10,...
                'BackgroundColor','white',...
                'Position',[87 5 60 20],...
                'Parent',  obj.autoFluoDetector.para,...
                'Callback',@obj.onoffResp);
            % Buttons
           
           obj.autoFluoDetector.processAutoDetection  =uicontrol('Style','pushbutton',...
               'String','Detect',...
               'BackgroundColor','white',...
               'Position',[90 10 60 25],...
               'Parent',obj.autoFluoDetector.fig,...
               'Callback',@obj.processAutoDetection);
        end
        
        function autoFluoDetectionClose (obj,hObject, ~)
            
            delete(hObject);
            obj.autoFluoDetector=[];
        end
           
        function withSti (obj,hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.autoFluoDetector.withoutSti,'Value',0)
            end
            
        end
        
        function withoutSti (obj,hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.autoFluoDetector.withSti,'Value',0)
            end
            
        end
        
        function onResp (obj,hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.autoFluoDetector.offResp,'Value',0)
                    set (obj.autoFluoDetector.onoffResp,'Value',0)
            end
            
        end
        
        function offResp (obj,hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.autoFluoDetector.onResp,'Value',0)
                    set (obj.autoFluoDetector.onoffResp,'Value',0)
            end
            
        end
        
        function onoffResp (obj,hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.autoFluoDetector.onResp,'Value',0)
                    set (obj.autoFluoDetector.offResp,'Value',0)
            end
            
        end
        % function to detect fluorescence change automatically
        function processAutoDetection (obj,hObject, ~)
            
            if get(obj.autoFluoDetector.withoutSti, 'Value')
                set(obj.infoTxt, 'String', 'Not Supported Yet!');
                return;
            end
            
            if get (obj.autoFluoDetector.onResp,'Value')
                option=0;
            elseif get (obj.autoFluoDetector.offResp,'Value')
                option=1;
            else
                option=2;
            end
            
            [fluoChangeData]=caculateFluoChange(obj,option);
%             filteredFluoChangeData=moving_average(fluoChangeData,1);
            filteredFluoChangeData=100*fluoChangeData;
            showFluoChange(obj,hObject,filteredFluoChangeData);
            
        end
        
        function [fluoChangeData]=caculateFluoChange(obj,option)
            
            % channel info
            if obj.data.metadata.iminfo.channel==1
                chN=1;
            else
                chN=get(obj.chSlider,'Value');
            end
            % detect whether fluoChangeData already exits
%             switch option
%                 case 0
%                     try fluoChangeData=obj.data.metadata.hotSpotFrame.on{chN};return;
%                     catch    
%                     end
%                 case 1
%                     try fluoChangeData=obj.data.metadata.hotSpotFrame.off{chN};return;
%                     catch    
%                     end
%                 case 2
%                     try fluoChangeData=obj.data.metadata.hotSpotFrame.off{chN};return;
%                     catch    
%                     end
%             end
            
            % test whether there is stimulus infomation 
            try
                 stiInfo=obj.stiTool;
            catch
                try
                    stiInfo=obj.data.metadata.stiInfo;
                catch
                stimulus(obj);
                waitfor(obj.stiTool.h.fig);
                stiInfo=obj.stiTool;
                end
                
            end
            
            % image info
            frameRate=obj.data.metadata.iminfo.framePeriod;            
            
            % check whether show on, off or both
            nSti    =length(stiInfo.trailInfo);
            
%             onStart =stiInfo.startFrameN;
%             onEnd   =stiInfo.endFrameN;
%             offStart=stiInfo.endFrameN+1;
%             offEnd =stiInfo.endFrameN+round(2/frameRate);
            for i=1:nSti
            onStart(i) =stiInfo.trailInfo(i).startFrameN;
            onEnd(i)   =stiInfo.trailInfo(i).endFrameN;
            offStart(i)=stiInfo.trailInfo(i).endFrameN+1;
            offEnd(i) =stiInfo.trailInfo(i).endFrameN+round(2/frameRate);%show on cells 
            end
            
            % load imagedata
            if ~obj.data.info.immat.loaded
                if exist(obj.data.info.immat.name,'file')
                    obj.data.imagedata=getfield(load(obj.data.info.immat.name),'imagedata');
                    obj.data.info.immat.loaded=1;
                end
            end
            
            sum1     =0;
            sum2     =0;
            switch option
                case 0
                    for i=1:nSti
                        sum1=sum1+squeeze(mean(obj.data.imagedata(:,:,chN,onStart(i):onEnd(i)),4));
                        sum2=sum2+squeeze(mean(obj.data.imagedata(:,:,chN,onStart(i)-round(5/frameRate):onStart(i)),4));
                    end
                    fluoChangeData=sum1/nSti;
                    baselineData=sum2/nSti;
                    fluoChangeData=fluoChangeData-baselineData;
                    obj.data.metadata.hotSpotFrame.on{chN}=fluoChangeData;
                case 1
                    for i=1:nSti
                        sum1=sum1+squeeze(mean(obj.data.imagedata(:,:,chN,offStart(i):offEnd(i)),4));
                    end
                    fluoChangeData=sum1/nSti;
                    fluoChangeData=fluoChangeData-obj.data.metadata.previewFrame{chN};
                    obj.data.metadata.hotSpotFrame.off{chN}=fluoChangeData;
                case 2
                    for i=1:nSti
                        sum1=sum1+squeeze(mean(obj.data.imagedata(:,:,chN,onStart(i):onEnd(i)),4))+squeeze(mean(obj.data.imagedata(:,:,chN,offStart(i):offEnd(i)),4));
                    end
                    fluoChangeData=sum1/nSti;
                    fluoChangeData=fluoChangeData-2*obj.data.metadata.previewFrame{chN};
                    obj.data.metadata.hotSpotFrame.all{chN}=fluoChangeData;
                    
            end
        end
        
        function showFluoChange(obj,hObject,fluoChangeData)
            
            axes(obj.axes1);
%             cla ;
            
            magN     = obj.openStates.image.magN;
            zoomFactor= obj.openStates.image.zoomFactor; 
            
            hAxes1 = get(obj.axes1,'Children');
            delete (hAxes1(end));
            hAxes1(end)=[];
            nhAxes1=length(hAxes1);
            
            hAxes1(nhAxes1+1)=imagesc(fluoChangeData, 'Parent',obj.axes1);axis off;drawnow;colormap(gray);
            obj.openStates.curImage=fluoChangeData;
            
            if ~isfield(obj.openStates,'roi')
                if zoomFactor
                    startZoomMagN=magN-zoomFactor;
                    zoom (obj.mag(magN)/obj.mag(startZoomMagN));
                end
            end
                
            curhAxes1=get(obj.axes1,'Children');
            if hAxes1(end)~=curhAxes1(end)
                set(obj.axes1,'Children',hAxes1);
            end
            % force the slider to lose focus, so to use KeyPressFcn for zoomImage. This is very much a hack.
            set(hObject, 'Enable', 'off');
            figure(obj.dispFig);
            drawnow;
            set(hObject, 'Enable', 'on');
           
        end
        
        % brightnessOverTime figure
        function fluoChangeProcessor (obj, ~, ~)
            
            if isempty(obj.fluoAnalyzer)
                initFluoChangeProcessor (obj)
            end
        end
        
        % initialize gui for brightnessOverTime figure
        function initFluoChangeProcessor (obj)
            
            roiFigPos=get(obj.roiTool.fig,'Position');
               
            obj.fluoAnalyzer.fig  =figure   ('Name','Brightness Over Time','NumberTitle','off',...
                                             'MenuBar','none','Position',[roiFigPos(1)+roiFigPos(3)+20 roiFigPos(2)+roiFigPos(4)-400 200 400],...
                                             'Resize','off','Color','white',...
                                             'CloseRequestFcn',@obj.fluoChangeProcessorClose);
           %Creat uicontrol
           obj.fluoAnalyzer.curRoi                =uicontrol('Style','radiobutton',...
               'String','CurROI',...
               'Value',1,...
               'BackgroundColor','white',...
               'Position',[15 375 70 20],...
               'Parent', obj.fluoAnalyzer.fig,...
               'Callback',@obj.curRoi);
           obj.fluoAnalyzer.allRois               =uicontrol('Style','radiobutton',...
               'String','AllROIs',...
               'BackgroundColor','white',...
               'Position',[110 375 70 20],...
               'Parent', obj.fluoAnalyzer.fig,...
               'Callback',@obj.allRois);
           % Response parameter panel
            obj.fluoAnalyzer.responsePara          =uipanel('Title','Response',...
               'FontSize',10,...
               'BackgroundColor','white',...
               'Units','pixels',...
               'Position',[10 265 180 110],...
               'Parent',  obj.fluoAnalyzer.fig);
            obj.fluoAnalyzer.filterTxt             =uicontrol('Style','text',...
               'String','Filter:',...
               'BackgroundColor','white',...
               'Position',[46 70 35 20],...
               'Parent', obj.fluoAnalyzer.responsePara);
            obj.fluoAnalyzer.filterEdit            =uicontrol('Style','Edit',...
               'String','0',...
               'BackgroundColor','white',...
               'Position',[100 74 60 16],...
               'Parent', obj.fluoAnalyzer.responsePara);
            obj.fluoAnalyzer.baselineTxt           =uicontrol('Style','text',...
               'String','Baseline:',...
               'BackgroundColor','white',...
               'Position',[23 50 60 20],...
               'Parent', obj.fluoAnalyzer.responsePara);
            obj.fluoAnalyzer.baselineEdit          =uicontrol('Style','Edit',...
               'String','10',...
               'BackgroundColor','white',...
               'Position',[100 54 60 16],...
               'Parent', obj.fluoAnalyzer.responsePara);
            obj.fluoAnalyzer.traceLengthTxt        =uicontrol('Style','text',...
               'String','TraceLength:',...
               'BackgroundColor','white',...
               'Position',[1 30 85 20],...
               'Parent', obj.fluoAnalyzer.responsePara);
           obj.fluoAnalyzer.traceLengthEdit       =uicontrol('Style','Edit',...
               'String','10',...
               'BackgroundColor','white',...
               'Position',[100 34 60 16],...
               'Parent', obj.fluoAnalyzer.responsePara);
            obj.fluoAnalyzer.wholeTrail          =uicontrol('Style','radiobutton',...
               'String','Raw',...
               'BackgroundColor','white',...
               'Position',[5 10 90 20],...
               'Parent',  obj.fluoAnalyzer.responsePara,...
               'Callback',@obj.wholeTrail);
           obj.fluoAnalyzer.trailByTrail          =uicontrol('Style','radiobutton',...
               'String','Trail',...
               'BackgroundColor','white',...
               'Position',[55 10 90 20],...
               'Parent',  obj.fluoAnalyzer.responsePara,...
               'Callback',@obj.trailByTrail); 
            obj.fluoAnalyzer.average               =uicontrol('Style','radiobutton',...
               'String','Ave',...
               'BackgroundColor','white',...
               'Position',[110 10 70 20],...
               'Parent',  obj.fluoAnalyzer.responsePara,...
               'Callback',@obj.averageTrail);
           
           % Axis parameter panel
           obj.fluoAnalyzer.axisPara              =uipanel('Title','Axis',...
               'FontSize',10,...
               'BackgroundColor','white',...
               'Units','pixels',...
               'Position',[10 145 180 120],...
               'Parent', obj.fluoAnalyzer.fig);
           obj.fluoAnalyzer.xminTxt               =uicontrol('Style','text',...
               'String','Xmin:',...
               'BackgroundColor','white',...
               'Position',[42 80 40 20],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.xminEdit              =uicontrol('Style','Edit',...
               'String','-2',...
               'BackgroundColor','white',...
               'Position',[100 84 60 16],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.xmaxTxt               =uicontrol('Style','text',...
               'String','Xmax:',...
               'BackgroundColor','white',...
               'Position',[41 60 40 20],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.xmaxEdit              =uicontrol('Style','Edit',...
               'String','35',...
               'BackgroundColor','white',...
               'Position',[100 64 60 16],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.yminTxt               =uicontrol('Style','text',...
               'String','Ymin:',...
               'BackgroundColor','white',...
               'Position',[42 40 40 20],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.yminEdit              =uicontrol('Style','Edit',...
               'String','-50',...
               'BackgroundColor','white',...
               'Position',[100 44 60 16],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.ymaxTxt               =uicontrol('Style','text',...
               'String','Ymax:',...
               'BackgroundColor','white',...
               'Position',[41 20 40 20],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.ymaxEdit              =uicontrol('Style','Edit',...
               'String','100',...
               'BackgroundColor','white',...
               'Position',[100 24 60 16],...
               'Parent',obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.showAxis              =uicontrol('Style','radiobutton',...
               'String','Axis',...
               'Value',1,...
               'BackgroundColor','white',...
               'Position',[5 3 80 20],...
               'Parent', obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.expData              =uicontrol('Style','radiobutton',...
               'String','expData',...
               'BackgroundColor','white',...
               'Position',[55 3 80 20],...
               'Parent', obj.fluoAnalyzer.axisPara);
           obj.fluoAnalyzer.ds              =uicontrol('Style','radiobutton',...
               'String','DS',...
               'BackgroundColor','white',...
               'Position',[125 3 80 20],...
               'Parent', obj.fluoAnalyzer.axisPara);
           % Layout parameter panel
           obj.fluoAnalyzer.layoutPara            =uipanel('Title','Layout',...
               'FontSize',10,...
               'BackgroundColor','white',...
               'Units','pixels',...
               'Position',[10 35 180 110],...
               'Parent', obj.fluoAnalyzer.fig);
           obj.fluoAnalyzer.rowTxt                =uicontrol('Style','text',...
               'String','Row:',...
               'BackgroundColor','white',...
               'Position',[45 70 40 20],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.rowEdit               =uicontrol('Style','Edit',...
               'String','1',...
               'BackgroundColor','white',...
               'Position',[100 74 60 16],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.colTxt                =uicontrol('Style','text',...
               'String','Col:',...
               'BackgroundColor','white',...
               'Position',[48 50 40 20],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.colEdit               =uicontrol('Style','Edit',...
               'String','1',...
               'BackgroundColor','white',...
               'Position',[100 54 60 16],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.intervalTxt           =uicontrol('Style','text',...
               'String','Interval:',...
               'BackgroundColor','white',...
               'Position',[27 30 60 20],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.intervalEdit          =uicontrol('Style','Edit',...
               'String','1',...
               'BackgroundColor','white',...
               'Position',[100 34 60 16],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.color                  =uicontrol('Style','text',...
               'String','Color:',...
               'BackgroundColor','white',...
               'Position',[5 5 40 20],...
               'Parent',obj.fluoAnalyzer.layoutPara);
           obj.fluoAnalyzer.blackColor          =uicontrol('Style','radiobutton',...
               'String','B',...
               'BackgroundColor','white',...
               'Position',[55 8 45 20],...
               'Parent',  obj.fluoAnalyzer.layoutPara,...
               'Callback',@obj.blackColor);
           obj.fluoAnalyzer.redColor          =uicontrol('Style','radiobutton',...
               'String','R',...
               'BackgroundColor','white',...
               'Position',[95 8 40 20],...
               'Parent',  obj.fluoAnalyzer.layoutPara,...
               'Callback',@obj.redColor); 
            obj.fluoAnalyzer.blueColor               =uicontrol('Style','radiobutton',...
               'String','B',...
               'BackgroundColor','white',...
               'Position',[130 8 40 20],...
               'Parent', obj.fluoAnalyzer.layoutPara,...
               'Callback',@obj.blueColor);
           
           % Buttons
           
           obj.fluoAnalyzer.saveProcessPara       =uicontrol('Style','pushbutton',...
               'String','Save',...
               'BackgroundColor','white',...
               'Position',[30 10 60 25],...
               'Parent',obj.fluoAnalyzer.fig,...
               'Callback',@obj.saveProcessPara);
           obj.fluoAnalyzer.processROI            =uicontrol('Style','pushbutton',...
               'String','Process',...
               'BackgroundColor','white',...
               'Position',[95 10 60 25],...
               'Parent',obj.fluoAnalyzer.fig,...
               'Callback',@obj.processROI);
           
           % Initiazing
           if isfield(obj.data.metadata,'processPara')
               set(obj.fluoAnalyzer.filterEdit, 'String', obj.data.metadata.processPara.filter);
               set( obj.fluoAnalyzer.baselineEdit , 'String', obj.data.metadata.processPara.baselineLength);
               set(obj.fluoAnalyzer.traceLengthEdit, 'String', obj.data.metadata.processPara.traceLength);
               set(obj.fluoAnalyzer.yminEdit , 'String', obj.data.metadata.processPara.ymin);
               set(obj.fluoAnalyzer.ymaxEdit , 'String', obj.data.metadata.processPara.ymax);
           end
               
               
        end
        
        function fluoChangeProcessorClose (obj,hObject, ~)
            
            delete(hObject);
            obj.fluoAnalyzer=[];
        end
        
        % Function to select current ROI
        function curRoi(obj,hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.allRois ,'Value',0)
            end
            
            set(obj.fluoAnalyzer.rowEdit,'String',1);
            set(obj.fluoAnalyzer.colEdit,'String',1);
        end
        
        % Function to select current all ROIs
        function allRois(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.curRoi ,'Value',0)
            end
            nROIs=length(obj.data.metadata.ROIdata);
            
            prompt={'Enter # of first ROI','Enter # of last ROI'};
            dlg_title='Choose ROIs';
            num_lines=1;
            
            def={'1',num2str(nROIs)};
            p=str2double(inputdlg(prompt,dlg_title,num_lines,def));
            setappdata(obj.fluoAnalyzer.allRois,'ROIs',p);
            
            if get(obj.fluoAnalyzer.wholeTrail,'Value')&& nROIs<=5
                iniColValue=1;
                iniRowValue=nROIs;
            else
                 iniColValue=ceil(sqrt((p(2)-p(1)+1)));
                iniRowValue=ceil((p(2)-p(1)+1)/iniColValue);
            end
            
            set(obj.fluoAnalyzer.rowEdit,'String',iniRowValue);
            set(obj.fluoAnalyzer.colEdit,'String',iniColValue);
            
%             set(obj.roiTool.roiList,'Value',1); 
%             obj.openStates.roi.curRoiN=[];
%             obj.openStates.roi.curRoih=[];

        end
        
        function blackColor(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.redColor,'Value',0)
                    set (obj.fluoAnalyzer.blueColor,'Value',0)  
            end
        end
        
        function redColor(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.blackColor,'Value',0)
                    set (obj.fluoAnalyzer.blueColor,'Value',0)  
            end
        end
        
        function blueColor(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.redColor,'Value',0)
                    set (obj.fluoAnalyzer.blackColor,'Value',0)  
            end
        end
        
        % Function to show the whole recording by deltaF/F
        function wholeTrail(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.trailByTrail,'Value',0)
                    set (obj.fluoAnalyzer.average,'Value',0)
                    
            end
            
            nFrames  =obj.data.metadata.iminfo.framenumber;
            frameRate=obj.data.metadata.iminfo.framePeriod;
            
            iniXmax=nFrames*frameRate+2;
            set(obj.fluoAnalyzer.xmaxEdit,'String',iniXmax);
        end
        
        % Function to show trail by trail with deltaF/F
        function trailByTrail(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.wholeTrail,'Value',0)
                    set (obj.fluoAnalyzer.average,'Value',0)
            end
            
            trailInterval=str2double(get(obj.fluoAnalyzer.intervalEdit ,'String'));
            trace=str2double(get(obj.fluoAnalyzer.traceLengthEdit,'string'));
            
            try
                nSti =length(obj.stiTool.trailInfo);
            catch
                try
                    nSti =length(obj.data.metadata.stiInfo.trailInfo);
                catch
                    stimulus(obj);
                    waitfor(obj.stiTool.hfig);
                    nSti=length(obj.stiTool.trailInfo);
                end
            end
            
            iniXmax=(trace+1+trailInterval)*nSti-trailInterval+2;
            set(obj.fluoAnalyzer.xmaxEdit,'String',iniXmax);
            
        end
        
        % Function to show averaged trail with deltaF/F
        function averageTrail(obj, hObject, ~)
            
            switch get(hObject,'Value')
                case 0
                    set(hObject,'Value',1)
                case 1
                    set (obj.fluoAnalyzer.wholeTrail,'Value',0)
                    set (obj.fluoAnalyzer.trailByTrail,'Value',0)
            end
            
            trailInterval=str2double(get(obj.fluoAnalyzer.intervalEdit ,'String'));
            trace=str2double(get(obj.fluoAnalyzer.traceLengthEdit,'string'));
            
            try
                patN=length(obj.stiTool.patternInfo);
            catch
                try
                    patN =length(obj.data.metadata.stiInfo.patternInfo);
                catch
%                     stimulus(obj);
                         stim(obj);
                    return;
                end
            end
            iniXmax=(trace+1+trailInterval)*patN-trailInterval+2;
            set(obj.fluoAnalyzer.xmaxEdit,'String',iniXmax);
        end
        
        % Function to save process parameters
        function saveProcessPara (obj, ~, ~)
            
            load(obj.data.info.metamat.name);
            metadata.processPara=obj.data.metadata.processPara;
%             metadata=obj.data.metadata;
            save(obj.data.info.metamat.name, 'metadata');
            set(obj.infoTxt,'string','Processing Parameters Saved!');
        end
        
        % Function to process Roi
        function processROI (obj, ~, ~)
            
            set(obj.infoTxt,'string','Processing...');

            % image info
            try
            nFrames  =obj.data.metadata.iminfo.framenumber;
            catch
                nFrames  =obj.data.metadata.iminfo.frameNumber;
            end
            frameRate=obj.data.metadata.iminfo.framePeriod;
            fluoTime =frameRate*(1:1:nFrames);
            
            % channel info
            if obj.data.metadata.iminfo.channel==1
                chN=1;
            else
                chN=get(obj.chSlider,'Value');
            end
            
            % roi info
            try
                nROIs=length(obj.data.metadata.ROIdata);
            catch
                set(obj.infoTxt,'string','Error! No ROIs!');
                return;
            end
            
            % reading from the panel
            avenum         =str2double(get(obj.fluoAnalyzer.filterEdit,'String')); obj.data.metadata.processPara.filter=avenum;
            baselineLength =round(str2double(get(obj.fluoAnalyzer.baselineEdit,'String'))/frameRate); obj.data.metadata.processPara.baselineLength=str2double(get(obj.fluoAnalyzer.baselineEdit,'String'));
            traceLength    =round(str2double(get(obj.fluoAnalyzer.traceLengthEdit,'String'))/frameRate); obj.data.metadata.processPara.traceLength=str2double(get(obj.fluoAnalyzer.traceLengthEdit,'String'));
             
            xmin=str2double(get(obj.fluoAnalyzer.xminEdit,'String')); 
            xmax=str2double(get(obj.fluoAnalyzer.xmaxEdit,'String'));
            ymin=str2double(get(obj.fluoAnalyzer.yminEdit,'String')); obj.data.metadata.processPara.ymin=ymin;
            ymax=str2double(get(obj.fluoAnalyzer.ymaxEdit,'String')); obj.data.metadata.processPara.ymax=ymax;
            
            row=str2double(get(obj.fluoAnalyzer.rowEdit,'String'));
            col=str2double(get(obj.fluoAnalyzer.colEdit,'String'));
            trailInterval=round(str2double(get(obj.fluoAnalyzer.intervalEdit,'String'))/frameRate); 
            
            % roi information
            selectIndex=obj.openStates.roi.curRoiN;
            curROI=obj.openStates.roi.curRoih;
           
           % stimulus information
%            if ~get(obj.fluoAnalyzer.wholeTrail,'Value')
               try
                   stidata=obj.stiTool.data(:,3);
                   trailInfo= obj.stiTool.trailInfo;
                   patternInfo1=obj.stiTool.patternInfo;
                   %                s=obj.stiTool.startFrameN;
                   
               catch
                   stidata=obj.data.metadata.stiInfo.data(:,3);
                   trailInfo= obj.data.metadata.stiInfo.trailInfo;
                   patternInfo1=obj.data.metadata.stiInfo.patternInfo;
                   %                s=obj.data.metadata.stiInfo.startFrameN;
                   
               end
               
               try
                   s=obj.stiTool.startFrameN;
               catch
                   try
                       s=obj.data.metadata.stiInfo.startFrameN;
                   catch
                       s=cell2mat({trailInfo.startFrameN});  % for new stimulus tool (stim)
                   end
               end
               
               nSti=length(trailInfo);
               nPat=length(patternInfo1);
               stidata=stidata*( ymax/max(stidata)/2)+ymin;
               
               if ~iscell(patternInfo1)
                   for i=1:nPat
                       patternInfo{i}.trailN=patternInfo1(i).trailN;
                   end
               else
                   patternInfo=patternInfo1;
               end
               
%            end
           
            % raw selected, 
            if get(obj.fluoAnalyzer.wholeTrail,'Value')
                               
                if get(obj.fluoAnalyzer.curRoi,'Value')
                    [intensityAve]=getintensity(obj,selectIndex,chN);
                    f=moving_average(intensityAve,avenum);
                    
                    F0            = mean(f(1:baselineLength));
                    RelativeF     = (f-F0)/F0*100;
                    
                    figure(30);
                     baseline=zeros(nFrames,1);
                    plot(fluoTime,RelativeF, fluoTime, stidata,fluoTime,baseline,'--k','LineWidth',1);
                    axis([xmin xmax ymin ymax])
                    if ~get(obj.fluoAnalyzer.showAxis,'Value')
                        axis off;
                    end
                elseif get(obj.fluoAnalyzer.allRois,'Value')
                    
                    baseline=zeros(nFrames,1);
                    for j=1:nROIs
                        [intensityAve]=getintensity(obj,j,chN);
                        f(:,j)=moving_average(intensityAve,avenum);
                        
                        F0(j)              = mean(f(1:baselineLength,j));
                        RelativeF(:,j)     = (f(:,j)-F0(j))/F0(j)*100;
                        
                        figure(40);
                        subplot(row,col,j);plot(fluoTime,RelativeF(:,j), fluoTime, stidata,fluoTime,baseline,'--k','LineWidth',1);
                        axis([xmin xmax ymin ymax])
                        if ~get(obj.fluoAnalyzer.showAxis,'Value')
                            axis off;
                        end
                        hold on;
                    end
                end                
                
                return;
            end
  
            % light responses
            
            if baselineLength > s(1) || baselineLength > s(2)-s(1)
                set(obj.infoTxt,'string','Error! BaseLine value is too big!');
                return;
            end

            if traceLength > s(2)-s(1)
                set(obj.infoTxt,'string','Error! TraceLength value is too big!');
                return;
            end

            % needs improvements
            startFrame    = s;
            prestartFrame = startFrame-round(1/frameRate);
            baselineFrame = startFrame-baselineLength;
            traceFrame    = startFrame + traceLength-1;
            responseLength= traceLength+round(1/frameRate);
                      
            if get(obj.fluoAnalyzer.curRoi,'Value')
                [intensityAve]=getintensity(obj,selectIndex,chN);
                f=moving_average(intensityAve,avenum);
                
                for k=1:nSti
                    F(:,k)           = f(prestartFrame(k):traceFrame(k));
                    F0(k)            = mean(f(baselineFrame(k):startFrame(k)));
                    RelativeF(:,k)   = ( F(:,k)-F0(k))/F0(k)*100;
                end
                
%                 response=figure ('name',[obj.openStates.image.fileName(end-3:end) '-' num2str(selectIndex)],'NumberTitle','off');
%                 set(response,'color',[0.729 0.831 0.957])
                figure(505);
                if get(obj.fluoAnalyzer.trailByTrail,'Value')
                    for k=1:nSti
                        t=frameRate*((responseLength+trailInterval)*(k-1)+1:1:k*(responseLength+trailInterval)-trailInterval);
                        sti= stidata(prestartFrame(k):traceFrame(k));
                        baseline=zeros(1,traceLength+round(1/frameRate));
                        plot(t,RelativeF(:,k),t,sti,t,baseline,'--k','LineWidth',1);
                        axis([xmin xmax ymin ymax])
                        if ~get(obj.fluoAnalyzer.showAxis,'value')
                            axis off;
                        end
                        hold on;
                    end
                elseif get(obj.fluoAnalyzer.average,'Value')
                    for i=1:nPat
                        t=frameRate*((responseLength+trailInterval)*(i-1)+1:1:i*(responseLength+trailInterval)-trailInterval);
                        nTrail=length(patternInfo{i}.trailN);
                        total=[];
                        for n=1:nTrail
                            trailN=patternInfo{i}.trailN(n);
                            total(:,n)=RelativeF(:,trailN);
                            h=plot(t,RelativeF(:,trailN),'k','LineWidth',1);
                            set(h,'color',[0.827 0.827 0.827]);
                            axis([xmin xmax ymin ymax])
                            if ~get(obj.fluoAnalyzer.showAxis,'value')
                                axis off;
                            end
                            hold on;
                        end
                        traceAve(:,i)=sum(total(:,:),2)/nTrail;
                        firstTrail=patternInfo{i}.trailN(1);
                        sti(:,i)=stidata(prestartFrame(firstTrail):traceFrame(firstTrail));% needs attention!
                        baseline=zeros(1,traceLength+round(1/frameRate));
                        if get(obj.fluoAnalyzer.blueColor,'Value')
                            plot(t,traceAve(:,i),'b',t,sti(:,i),t,baseline,'--r','LineWidth',1.5);
                        elseif get(obj.fluoAnalyzer.redColor,'Value')
                            plot(t,traceAve(:,i),'r',t,sti(:,i),t,baseline,'--r','LineWidth',1.5);
                        else
                            plot(t,traceAve(:,i),'k',t,sti(:,i),t,baseline,'--r','LineWidth',1.5);
                        end
                        axis([xmin xmax ymin ymax])
                        if ~get(obj.fluoAnalyzer.showAxis,'value')
                            axis off;
                        end
                        
                        
                    end
                    
                    % ANALYSIS MODULE FOR DS
                        if get(obj.fluoAnalyzer.ds,'Value')
                            %first, get peak value for ON and OFF response,
                            %regardness of ON, OFF, ON-OFF cells (need
                            %improvements
                            
                            %Define ON, OFF based on stimulus
                           stiDuration=trailInfo(1).endFrameN-trailInfo(1).startFrameN+1;
                           stiOn=round(1/frameRate); stiEnd=stiOn+stiDuration-1;
                           for i=1:nPat %nPat here equals to n of directions
                               onPeak(i) =max(traceAve(stiOn:stiEnd,i));
                               offPeak(i)=max(traceAve(stiEnd+1:end,i));
                           end

                           onds=ds(onPeak); offds=ds(offPeak);
                           dsindex(1)=onds.pd;dsindex(2)=onds.vpd;dsindex(3)=offds.pd;dsindex(4)=offds.vpd;dsindex(5)=onds.dsi;dsindex(6)=offds.dsi;
                           disp(dsindex);
                           
                            %Plot
                            figure(666);
                            polar([onds.data(:,1);2*pi],[onds.data(:,2);onds.data(1,2)],'r');
                            hold on;
                            polar([0 onds.pd/360*2*pi],[0 onds.vpd],'r');
                            hold on;
                            polar([offds.data(:,1);2*pi],[offds.data(:,2);offds.data(1,2)],'g');
                            hold on;
                            polar([0 offds.pd/360*2*pi],[0 offds.vpd],'g');
                            
                           
                        end
                end
                
                
            elseif get(obj.fluoAnalyzer.allRois,'Value')
                
                ROIn=getappdata(obj.fluoAnalyzer.allRois,'ROIs');
                
                if ~isempty(curROI)
                    delete(curROI); 
                    lineh=plot(obj.data.metadata.ROIdata{selectIndex}.pos(:,1),obj.data.metadata.ROIdata{selectIndex}.pos(:,2),'white', 'LineWidth',2,'Parent', obj.axes1);
                    obj.data.metadata.ROIdata{selectIndex}.linehandles=lineh;
                    obj.openStates.roi.curRoiN=1;
                    obj.openStates.roi.curRoih=[];
                end
                
               for j=ROIn(1):ROIn(2)
                    intensityAve=[];
                    [intensityAve]=getintensity(obj,j,chN);
                    f=moving_average(intensityAve,avenum);
                    
                    for k=1:nSti
                        F(:,k,j)           = f(prestartFrame(k):traceFrame(k));
                        F0(k,j)            = mean(f(baselineFrame(k):startFrame(k)));
                        RelativeF(:,k,j)   = ( F(:,k,j)-F0(k,j))/F0(k,j)*100;
                    end
                    
                    
                    if get(obj.fluoAnalyzer.trailByTrail,'Value')
                        for k=1:nSti
                            t=frameRate*((responseLength+trailInterval)*(k-1)+1:1:k*(responseLength+trailInterval)-trailInterval);
                            sti= stidata(prestartFrame(k):traceFrame(k));
                            baseline=zeros(1,traceLength+round(1/frameRate));
                            figure(303);
                            subplot(row,col,j-ROIn(1)+1);plot(t,RelativeF(:,k,j),t,sti,t,baseline,'--k','LineWidth',1);
                            axis([xmin xmax ymin ymax])
                            if ~get(obj.fluoAnalyzer.showAxis,'value')
                                axis off;
                            end
                            hold on;
                        end
                    elseif get(obj.fluoAnalyzer.average,'Value')
                        
                        figure(404);
                        for i=1:nPat
                            t=frameRate*((responseLength+trailInterval)*(i-1)+1:1:i*(responseLength+trailInterval)-trailInterval);
                            nTrail=length(patternInfo{i}.trailN);
                            totalAll=[];
                            for n=1:nTrail
                                trailN=patternInfo{i}.trailN(n);
                                totalAll(:,n,j)=RelativeF(:,trailN,j);
                                
                                subplot(row,col,j);h=plot(t,RelativeF(:,trailN,j),'k','LineWidth',0.5);
                                set(h,'color',[0.827 0.827 0.827]);
                                axis([xmin xmax ymin ymax])
                                if ~get(obj.fluoAnalyzer.showAxis,'value')
                                    axis off;
                                end
                                hold on;
                            end
                            traceAve(:,i,j)=sum(totalAll(:,:,j),2)/nTrail;
%                             peakAve(i,j)=max(traceAve(round(1/frameRate):round(6/frameRate),i,j));
                            firstTrail=patternInfo{i}.trailN(1);
                            sti(:,i)=stidata(prestartFrame(firstTrail):traceFrame(firstTrail));
                            baseline=zeros(1,traceLength+round(1/frameRate));
                            subplot(row,col,j-ROIn(1)+1);
                            if get(obj.fluoAnalyzer.blueColor,'Value')
                            plot(t,traceAve(:,i,j),'b',t, sti(:,i),t,baseline,'--k','LineWidth',1);
                            elseif get(obj.fluoAnalyzer.redColor,'Value')
                                plot(t,traceAve(:,i,j),'r',t, sti(:,i),t,baseline,'--k','LineWidth',1);
                            else
                                plot(t,traceAve(:,i,j),'k',t, sti(:,i),t,baseline,'--k','LineWidth',1);
                            end
                            axis([xmin xmax ymin ymax])
                            if ~get(obj.fluoAnalyzer.showAxis,'value')
                                axis off;
                            end
                        end
                        % ANALYSIS MODULE FOR DS
                        if get(obj.fluoAnalyzer.ds,'Value')
                            %first, get peak value for ON and OFF response,
                            %regardness of ON, OFF, ON-OFF cells (need
                            %improvements
                            
                            %Define ON, OFF based on stimulus
                           stiDuration=trailInfo(1).endFrameN-trailInfo(1).startFrameN+1;
                           stiOn=round(1/frameRate); stiEnd=stiOn+stiDuration-1;
                           for i=1:nPat %nPat here equals to n of directions
                               onPeak(j,i) =max(traceAve(stiOn:stiEnd,i,j));
                               offPeak(j,i)=max(traceAve(stiEnd+1:end,i,j));
                           end

                           onds=ds(onPeak(j,:)); offds=ds(offPeak(j,:));
                           dsindex(1)=onds.pd;dsindex(2)=onds.vpd;dsindex(3)=offds.pd;dsindex(4)=offds.vpd;dsindex(5)=onds.dsi;dsindex(6)=offds.dsi;
                           disp(dsindex);
                           
                            %Plot
                            figure(666);subplot(row,col,j-ROIn(1)+1);
                            polar([onds.data(:,1);2*pi],[onds.data(:,2);onds.data(1,2)],'r');
                            hold on;
                            polar([0 onds.pd/360*2*pi],[0 onds.vpd],'r');
                            hold on;
                            polar([offds.data(:,1);2*pi],[offds.data(:,2);offds.data(1,2)],'g');
                            hold on;
                            polar([0 offds.pd/360*2*pi],[0 offds.vpd],'g');
                            
                           
                        end
%                         maxResponse(:,j)    =max(peakAve(:,j));
%                         relativePeak(:,j)=peakAve(:,j)/maxResponse(:,j);
%                         for i=1:patN
%                             stiSize(i)=str2double(obj.stiTool.patternInfo{i}.info.size);
%                         end
%                         figure(5);
%                         subplot(row,col,j),plot(stiSize,relativePeak(:,j),'LineWidth',1.5);
                    end
                end
%                 relativePeakAve=sum(relativePeak,2)/nROIs;
%                 stdPeak        =std(relativePeak,0,2);
%                 maxRelativePeakAve=max(relativePeakAve);
%                 relativePeakAve=relativePeakAve/maxRelativePeakAve;
%                 stdPeak=stdPeak/maxRelativePeakAve;
%                 figure(6);
%                 errorbar(stiSize,relativePeakAve,stdPeak,'LineWidth',1.5);
%                 axis([0 1500 0 1.2])
%                 disp(stiSize)
%                 disp(relativePeakAve)
%                 disp(stdPeak)
            end
            
            set(obj.infoTxt,'string','Process done!');
            
            if get(obj.fluoAnalyzer.expData,'Value')
                
                outdata.t=frameRate*(1:1:responseLength);
                outdata.t=outdata.t';
                outdata.baseline=zeros(responseLength,1);
                outdata.sti=sti;
                
                L=size(RelativeF);
                if length(L)~=3
                outdata.relativeF=RelativeF;
                outdata.ave=traceAve;
                
                else
                    for i=1:L(3)
                        outdata.roi{i}.relativeF=RelativeF(:,:,i);
                        outdata.roi{i}.ave=traceAve(:,:,i);
                    end
                end
                
                save('output.mat','outdata');
                                
            end
%               load('output.mat');
%             if get(obj.fluoAnalyzer.expData,'Value')
%                 L=size(RelativeF);
%                 if length(L)~=3
%                     xlswrite('FileName.xlsx',RelativeF,1,'A1');
%                     try
%                         xlswrite('FileName.xlsx',traceAve,1,'F1');
%                     catch
%                     end
%                 else
%                     for i=1:L(3)
%                         xlswrite('FileName.xlsx',RelativeF(:,:,i),i,'A1');
%                         try
%                             xlswrite('FileName.xlsx',traceAve(:,:,i),i,'F1');
%                         catch
%                         end
%                     end
%                 end
%                 set(obj.infoTxt,'string','data was exported into excel!');
%             end
            
            %set(handles.ROIList,'Value',1);
%             clear all;
        end
        
    end
end


function waitbar_init(h_axes)

%h_axes is an axes handle
delete(get(h_axes,'Children'));
axis(h_axes,[0 1 0 1]);
axis(h_axes,'off');
rectangle('Position',[0 0 1 1],'Parent',h_axes,'FaceColor','w','EdgeColor',[0.94 0.94 0.94]);

end

function waitbar_fill(h_axes,fill)

c = get(h_axes,'Children');
if length(c) == 2
    if fill > 0
        set(c(1),'Position',[0 0 fill 1]);
        drawnow;
    elseif fill == 0
        delete(c(1));
    end
elseif fill > 0
    rectangle('Position',[0 0 fill 1],'Parent',h_axes,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[0.94 0.94 0.94]);
    %         drawnow;
end

end

function colorSelection(selected_color)

switch selected_color
    case 'Green'
        cmap=zeros(64,3);cmap(:,2)=0:1/63:1;colormap(cmap);
    case 'Red'
        cmap=zeros(64,3);cmap(:,1)=0:1/63:1;colormap(cmap);
    case 'Blue'
        cmap=zeros(64,3);cmap(:,3)=0:1/63:1;colormap(cmap);
    case 'Gray'
        colormap(gray);
    case 'Jet'
        colormap(jet);
end
        

end

