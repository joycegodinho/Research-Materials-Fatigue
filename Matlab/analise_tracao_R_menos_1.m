clc
clear
close all


filename = 'C:\Users\joyce\Dropbox\JOYCE\ANALISE2D\Dados\V_0_12_3D.txt';


%% Iniciar vari�veis.
NOME = 'C:\Users\joyce\Dropbox\JOYCE\ANALISE2D\Dados\V_0_12_3D';
filename = strcat(NOME,'.txt');
startRow = 2;

%% Ler colunas de dados como strings:
%Para mais informa��es , consulte a documenta��o TEXTSCAN .
formatSpec = '%13s%8s%[^\n\r]';

%% Abrir arquivo de texto.
fileID = fopen(filename,'r');

%% Ler colunas de dados de acordo com o formato string.
% Esta chamada � baseada na estrutura do arquivo utilizado para gerar este
% codigo. Se ocorrer um erro em um arquivo diferente , tentar regenerar o c�digo
% pela ferramenta de importa��o.
textscan(fileID, '%[^\n\r]', startRow-1, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);

%% Fechar arquivo de texto.
fclose(fileID);

%% Converter o conte�do das colunas que cont�m strings num�ricos para n�meros.
% Substituir strings nao numericas por NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2]
    % Converter strings na matriz da c�lula de entrada para n�meros. Substituir strings n�o num�rico
    % com NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Criar uma express�o regular para detectar e remover prefixos e sufixos n�o-num�ricos.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detectetar virgulas nas casas de milhares.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Converter strings num�ricos em n�meros.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


%% Excluir linhas com c�lulas n�o-num�ricas
J = ~all(cellfun(@(x) (isnumeric(x) || islogical(x)) && ~isnan(x),raw),2); % Find rows with non-numeric cells
raw(J,:) = [];

%% Alocar matrizes importadas na coluna dos nomes das vari�veis.
l = cell2mat(raw(:, 1));
S_REF = cell2mat(raw(:, 2));

%% Limpar variaveis temporarias.
clearvars filename startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me J;

%DEFINE A FAIXA DA TENS�O TRATIVA NA SE�AO GROSS

K = 100;

Sgmin = 41.7;
Sgmax = 200.2004;


%CARACTERIZA A CURVA DE FADIGA DO ESP�CIME ENTALHADO EM TRA��O

bg = -1/0.26954;
Ag = (1/2396.8)^bg;


%CARACTERIZA A CURVA DE FADIGA DO MATERIAL EM TRA�AO

Am = 933.67;
bm = -0.10707;



INC = (Sgmax-Sgmin)/(K-1);

for k=1:K
    
    Sg(k) = Sgmin + (k-1)*INC;
    
    S = S_REF*Sg(k);
    p = polyfit(S,l,8);
    
    % DEFINE  VIDA DE FADIGA ASSOCIADAS A TENSAO gross NO CP ENTALHADO
    
    N(k) = Ag*(Sg(k))^bg;
    
    % ESTIMA A TENS�O DE RESISTENCIA DO MAT. EM FADIGA

    Se(k) = Am*(N(k))^bm;

    % ESTIMA A DISTANCIA CR�TICA
    
    lp(k) = polyval(p,Se(k));

    
    Kfg(k) = Se(k)/Sg(k);
    
end

figure
subplot(2,1,1);
semilogx(N,lp);
xlabel('Num. de Ciclos para Falha');
ylabel('Distancia Critica [mm]');
subplot(2,1,2);
semilogx(N,Kfg)
xlabel('Num. de Ciclos para Falha');
ylabel('Fator de Red. de Resistencia a Fadiga');


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( N, lp );

%Configurar fittype e op��es.
ft = fittype( 'power1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [19.653305110338 -0.253858658369811];

% Ajustar modelo aos dados.
[result, gof] = fit( xData, yData, ft, opts );


result


TAM = length(S_REF);

D_EST = strcat(NOME,'.DAT');
fid = fopen(D_EST,'a');

for i=1:TAM
fprintf(fid,'%9.5e ;%9.5e\r\n',l(i),S_REF(i));    
end

fclose(fid);













