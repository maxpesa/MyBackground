%% PREPARAZIONE IMPOSTAZIONI
% dimensioni dei blocchetti 3D, si potrebbe deciderlo in base ad un
% divisore delle dimensioni.. oppure croppo violento?
X_BLOCK_LENGTH = 8;
Y_BLOCK_LENGTH = 8;
T_BLOCK_LENGTH = 3;

% threshold di rilevazione movimento come varianza sul blocchettino
VARIANCE_THRESHOLD = 10;


%% PREPARAZIONE VIDEO 
vid = VideoReader('res560.avi');
height = vid.Height;
width = vid.Width;
ncolors = 3;
nframes = vid.NumberOfFrames;
frames = zeros([height, width, ncolors, nframes + mod(nframes,T_BLOCK_LENGTH)]);
vid = VideoReader('res560.avi');
for i = 1:nframes
    frames(:,:,:,i) = vid.readFrame;
end
%sistemo nel caso il numero di frame, la width o altro non vadano bene
%sistemiamo il numero di frames

while (mod(nframes,T_BLOCK_LENGTH) > 0)
    frames(:,:,:,nframes+1) = frames(:,:,:,nframes);
    nframes = nframes + 1;
end


%% PREPARAZIONE MASCHERA
% preparo una matrice con i frame da salvare sporchi:
% è una matrice-maschera booleana che dice se un elemento (x,y,color,frame)
% deve appartenere al video in uscita, ovvero NON è SFONDO
disp('creating mask...');
save_mask = zeros([height, width, ncolors, nframes]);

%scorriamo frames a blocchetti [Y_BLOCK_LENGTH, X_BLOCK_LENGTH,:, T_BLOCK_LENGTH]
%valuteremo in ogni blocchetto se "c'è movimento" guardando se, entro una
%certa soglia, c'è variazione rispetto al primo mini-frame
disp('starting mask creation...');
%prealloccazione
to_check = zeros([Y_BLOCK_LENGTH, X_BLOCK_LENGTH, ncolors, T_BLOCK_LENGTH]);
N_x_blocks = width/X_BLOCK_LENGTH;
N_y_blocks = height/Y_BLOCK_LENGTH;
N_t_blocks = nframes/T_BLOCK_LENGTH;

%scorro nel tempo a gruppetti di T_BLOCK_LENGTH frames
for (t = 1:T_BLOCK_LENGTH:nframes)
    
    %scorro nelle x a gruppetti (blocchetti) di X_BLOCK_LENGTH
    for (x = 1:X_BLOCK_LENGTH:width)
       
        %scorro nelle y a gruppetti (blocchetti) di Y_BLOCK_LENGTH
        for (y = 1:Y_BLOCK_LENGTH:height) 
            
            %esaminiamo il blocchetto di dimensioni [Y_BLOCK_LENGTH, X_BLOCK_LENGTH,:, T_BLOCK_LENGTH]
            %offsettato di (y, x, :, t) (: perchè devo considerare tutti i piani colore)
            disp(['block (',num2str(y),',',num2str(x),',:,',num2str(t),') - ', num2str(t/nframes)]);
            to_check = frames(y:(y+Y_BLOCK_LENGTH-1), x:(x+X_BLOCK_LENGTH-1) ,:, t:(t+T_BLOCK_LENGTH-1));
            
            %per vedere se e quanto varia calcoliamo la varianza, pesata 1, può
            %essere buon indicatore?
            variance = var(to_check, 1,4);
            %variance è vettore [Y_BLOCK_LENGTH, X_BLOCK_LENGTH, 3] che mi
            %dice quanto varia nel tempo un certo pixel del blocchettino
            %che considero, PER OGNI PIANO COLORE -> posso gestirlo in modo
            %differente volendo
            if (any(variance > VARIANCE_THRESHOLD))
                %setto i particolari 1 come da salvare nella maschera
                save_mask(y:(y+Y_BLOCK_LENGTH-1), x:(x+X_BLOCK_LENGTH-1) ,:, t:(t+T_BLOCK_LENGTH-1)) = 1;
            end
            %caso contrario li faccio rimanere a zero
            
        end
        
    end
    
end


%% FORZATURA CONTINUITà SULLA MASCHERA
%parte più complicata: voglio che ci sia una certa CONTINUITA' nei
%salvataggi, ovvero che vengano salvati i punti "medi" (dove non è stato
%trovato il movimento) tra due punti "estremi" dove è stato trovato
%ricostruzione dei punti interni della maschera... quelli che non variano
%ma sono comunque soggetto...
%VOGLIO CHE SIANO SALVATI SIA I PUNTI INTERNI IN UNO STESSO FRAME CHE
%QUELLI NEL TEMPO (E CON UNA CERTA INTERPOLAZIONE (MA ANCHE HOLDING VA BENE))
disp('starting continuity forcing');


%% APPLICAZIONE MASCHERA
% prodotto cartesiano della maschera sporco...
disp('applying filter mask');
clean_frames = frames.*save_mask;

disp('process complete.');

disp('file saving');
func_videoExport(clean_frames, 'out560', vid.FrameRate);

