clc
clear
close all


filename = 'C:\Users\joyce\Dropbox\JOYCE\ANALISE2D\Dados\uflexao_3D.txt';

%% Iniciar variáveis.
NOME = 'C:\Users\joyce\Dropbox\JOYCE\ANALISE2D\Dados\uflexao_3D';
filename = strcat(NOME,'.txt');
startRow = 2;

%% Ler colunas de dados como strings:
%Para mais informações , consulte a documentação TEXTSCAN .
formatSpec = '%13s%8s%[^\n\r]';

%% Abrir arquivo de texto.
fileID = fopen(filename,'r');

%% Ler colunas de dados de acordo com o formato string.
% Esta chamada é baseada na estrutura do arquivo utilizado para gerar este
% codigo. Se ocorrer um erro em um arquivo diferente , tentar regenerar o código
% pela ferramenta de importação.
textscan(fileID, '%[^\n\r]', startRow-1, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);

%% Fechar arquivo de texto.
fclose(fileID);

%% Converter o conteúdo das colunas que contêm strings numéricos para números.
% Substituir strings nao numericas por NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2]
    % Converter strings na matriz da célula de entrada para números. Substituir strings não numérico
    % com NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Criar uma expressão regular para detectar e remover prefixos e sufixos não-numéricos.
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
            % Converter strings numéricos em números.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


%% Excluir linhas com células não-numéricas
J = ~all(cellfun(@(x) (isnumeric(x) || islogical(x)) && ~isnan(x),raw),2); % Find rows with non-numeric cells
raw(J,:) = [];

%% Alocar matrizes importadas na coluna dos nomes das variáveis.
l = cell2mat(raw(:, 1));
S_REF = cell2mat(raw(:, 2));

%% Limpar variaveis temporarias.
clearvars filename startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me J;

%DEFINE AS CURVAS DE CARACTERIZAÇÃO DO MATERIAL E D L VERSUS N

%CARACTERIZA A CURVA DE FADIGA DO MATERIAL EM TRAÇAO
Am = 4512.599;
bm = -0.22523;


%CARACTERIZA A CURVA DE FADIGA DO ESPÉCIME ENTALHADO EM FLEXAO (L versus N)
%Levantada a partir da análise de fadiga do cp com r = 0,383 mm

bg = 0.09109;
Ag = 0.2752;

%curva fadiga do especime entalhado

Anotch = 2987.314;
bnotch = -0.20843;

Nesp = 1E4;

ESCALA = Anotch*Nesp^(bnotch);

S = ESCALA*S_REF;

p = polyfit(l,S,8);

N_INF = 1E4;
N_MIN = 1E2;
DECREMENTO = 50;

FLAG = 1;

N_PRESC = N_INF

contador = 1

while FLAG

N_P(contador) = N_PRESC;
    
Lc_N = (1*Ag*N_PRESC^bg);

LC(contador) = Lc_N;

S_Lc_N =polyval(p,Lc_N);

S_L(contador) = S_Lc_N;

N_S_N = (S_Lc_N/Am)^(1/bm)

N_L(contador) = N_S_N;

ERRO = 100*abs(N_S_N - N_PRESC)/N_PRESC

if ERRO < 1
    FLAG = 0;
end

if N_PRESC < N_MIN
    FLAG = 0;
end

   
N_PRESC = abs(N_S_N + N_PRESC)/2
contador = contador + 1;
end

plot(LC,N_P,LC,N_L)