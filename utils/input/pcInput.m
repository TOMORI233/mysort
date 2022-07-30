function varargout = pcInput(varargin)
% pcInput MATLAB code for pcInput.fig
%      pcInput, by itself, creates a new pcInput or raises the existing
%      singleton*.
%
%      H = pcInput returns the handle to a new pcInput or the handle to
%      the existing singleton*.
%
%      pcInput('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in pcInput.M with the given input arguments.
%
%      pcInput('Property','Value',...) creates a new pcInput or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pcInput_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pcInput_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pcInput

% Last Modified by GUIDE v2.5 20-Jul-2022 15:26:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pcInput_OpeningFcn, ...
                   'gui_OutputFcn',  @pcInput_OutputFcn, ...
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


% --- Executes just before pcInput is made visible.
function pcInput_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pcInput (see VARARGIN)

try
    set(handles.PCx, 'string', num2str(varargin{1}));
    set(handles.PCy, 'string', num2str(varargin{2}));
end

% Choose default command line output for pcInput
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pcInput wait for user response (see UIRESUME)
uiwait(handles.pcInputFig);


% --- Outputs from this function are returned to the command line.
function varargout = pcInput_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
params = getappdata(handles.pcInputFig, 'params');
varargout{1} = params.PCx;
varargout{2} = params.PCy;
delete(hObject);


% --- Executes on button press in buttonOK.
function buttonOK_Callback(hObject, eventdata, handles)
%% Load params from appdata
params = getappdata(handles.pcInputFig, 'params');
%% TODO: Update your params here
% edit
params.PCx = str2double(get(handles.PCx, 'string'));
params.PCy = str2double(get(handles.PCy, 'string'));
%% Save params to appdata
setappdata(handles.pcInputFig, 'params', params);
uiresume(handles.pcInputFig);

% --- Executes during object creation, after setting all properties.
function PCx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PCx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function PCy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PCy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close pcInputFig.
function pcInputFig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to pcInputFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
try
    buttonOK_Callback(hObject, eventdata, handles);
catch
    delete(hObject);
end


% --- Executes on key press with focus on pcInputFig or any of its controls.
function pcInputFig_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pcInputFig (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    buttonOK_Callback(hObject, eventdata, handles);
end
