function varargout = clusterIdxInput(varargin)
% clusterIdxInput MATLAB code for clusterIdxInput.fig
%      clusterIdxInput, by itself, creates a new clusterIdxInput or raises the existing
%      singleton*.
%
%      H = clusterIdxInput returns the handle to a new clusterIdxInput or the handle to
%      the existing singleton*.
%
%      clusterIdxInput('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in clusterIdxInput.M with the given input arguments.
%
%      clusterIdxInput('Property','Value',...) creates a new clusterIdxInput or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before clusterIdxInput_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to clusterIdxInput_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help clusterIdxInput

% Last Modified by GUIDE v2.5 30-Jul-2022 14:53:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @clusterIdxInput_OpeningFcn, ...
                   'gui_OutputFcn',  @clusterIdxInput_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before clusterIdxInput is made visible.
function clusterIdxInput_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to clusterIdxInput (see VARARGIN)

try
    set(handles.idxShow, 'string', num2str(varargin{1}));
    set(handles.idxHide, 'string', num2str(varargin{2}));
end

% Choose default command line output for clusterIdxInput
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes clusterIdxInput wait for user response (see UIRESUME)
uiwait(handles.clusterIdxInputFig);


% --- Outputs from this function are returned to the command line.
function varargout = clusterIdxInput_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
params = getappdata(handles.clusterIdxInputFig, 'params');
varargout{1} = params.idxShow;
varargout{2} = params.idxHide;
delete(hObject);


% --- Executes on button press in buttonOK.
function buttonOK_Callback(hObject, eventdata, handles)
%% Load params from appdata
params = getappdata(handles.clusterIdxInputFig, 'params');
%% TODO: Update your params here
% edit
params.idxShow = eval(strcat('[', get(handles.idxShow, 'string'), ']'));
params.idxHide = eval(strcat('[', get(handles.idxHide, 'string'), ']'));
%% Save params to appdata
setappdata(handles.clusterIdxInputFig, 'params', params);
uiresume(handles.clusterIdxInputFig);

% --- Executes during object creation, after setting all properties.
function idxShow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to idxShow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function idxHide_CreateFcn(hObject, eventdata, handles)
% hObject    handle to idxHide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close clusterIdxInputFig.
function clusterIdxInputFig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to clusterIdxInputFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
try
    buttonOK_Callback(hObject, eventdata, handles);
catch
    delete(hObject);
end


% --- Executes on key press with focus on clusterIdxInputFig or any of its controls.
function clusterIdxInputFig_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to clusterIdxInputFig (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    buttonOK_Callback(hObject, eventdata, handles);
end
