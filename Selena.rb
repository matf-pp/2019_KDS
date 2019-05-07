require 'fox16'
include Fox
$promene={}
$Srpski=0
class Key
    def initialize(word=[], tezina=0, decomps=[])
        @word=word
        @tezina=tezina
        @decomps=decomps
    end
  
        def word
            @word
        end
        def tezina
            @tezina
        end
        def decomps
            @decomps
        end
        def word=(word)
            @word=word
        end
        def tezina=(tezina)
            @tezina=tezina
        end
        def decomps=(decomp)
            @decomps.append(decomp)
        end
    
  end
  
  class Decomp
    def initialize(parts=[], save=false, reasmbs=[])
        @parts=parts
        @save=save
        @reasmbs=reasmbs
        @next_reasmb_index=0
    end
    def parts
        @parts
   end
    def save
        @save
    end
    def reasmbs
        @reasmbs
    end
    def next_reasmb_index
        @next_reasmb_index
    end
    def parts=(parts)
        @parts=parts
    end
    def save=(save)
        @save=save
    end
    def reasmbs= (reasmbs)
       @reasmbs.append(reasmbs)
    end
    def next_reasmb_index=(next_reasmb_index)
        @next_reasmb_index=next_reasmb_index
    end
  end
  
  class Selena
    def initialize() 
        @initials=[]
        @finals=[]
        @quits=[]
        @pres={}
        @posts={}
        @synons={}
        @keys={}
        @memory=[]
        @glagoli={}
        @pridevi={}

    end
    def ucitaj(path)
        key=Key.new
        decomp=Decomp.new
        w=""
        File.open(path,"r").each do |line|
            line=line.chomp
            tag, content=line.split(": ")
           
            if tag=="initial"
                @initials.append(content)
            elsif tag.include?("final")
                @finals.append( content)
            elsif tag.include?("quit")
                @quits.append(content)
            elsif tag.include?("pre")
                parts=content.split(' ')
                @pres[parts[0]]=parts[1..-1]
            elsif tag.include? "post"
                parts=content.split(' ')
                i=1
                @posts[parts[0]]=parts[1..-1]
            elsif tag.include? "synon"
                parts=content.split(' ')
                @synons[parts[0]]=parts
            elsif tag.include? 'key'
                parts=content.split(' ')
                word=parts[0]
                unless parts.size==1
                    tezina=parts[1].to_i
                else
                    tezina=1
                end
                key=Key.new(word, tezina, [])
                @keys[word]=key
                w=word
            elsif tag.include? 'decomp'
                parts=content.split(' ')
                save=false
                if parts[0]=='$'
                    save=true
                    parts.delete_at(0)
                end 
                decomp=Decomp.new(parts, save, [])
                @keys[w].decomps=decomp
            elsif tag.include? "reasmb"
                parts=content.split(' ')
                decomp.reasmbs = parts 
            end
        end
        if $Srpski==1
            File.open("glagoli.txt","r").each do |line|
                line=line.chomp
                line=line.split(',')
                @glagoli[line[0]]=line
            end
            File.open("dodatne_reci.txt","r").each do |line|
                tag, content=line.split(": ")
                @pridevi[tag]=content.split(" ")
            end
        end
    end
    def _uparivanje_r(parts, words, rezultat)
        if parts.empty? && words.empty?
            return true
        end
        if parts.empty? || (words.empty? && parts!=['*'])
           return false
        end
        if parts[0].include?'*'
            words.length.step(-1,-1) do |i|
                rezultat.append(words[0...i])
                if _uparivanje_r(parts[1..-1], words[i..-1], rezultat)
                    return true
                end
                rezultat.pop
            end
            return false
        elsif parts[0].include?"@"
            koren=parts[0][1..-1]
            if !@synons[koren].include?(words[0].downcase)
                return false
            end
            rezultat.append([words[0]])
            return _uparivanje_r(parts[1..-1], words[1..-1], rezultat)
        elsif parts[0].downcase != words[0].downcase
            return false
        else
            return _uparivanje_r(parts[1..-1], words[1..-1], rezultat)
        end
    end
    def _uparivanje(delovi, reci)
        rezultat=[]
        if _uparivanje_r(delovi,reci,rezultat)
            return rezultat
        end
     
        return nil
    end
    def _spajanje_s(decomp)
        index=decomp.next_reasmb_index
        rezultat=decomp.reasmbs[index % decomp.reasmbs.length]
        decomp.next_reasmb_index=index+1
        return rezultat
    end
    def _spajanje(reasmb, rezultat)
        izlaz=[]
        reasmb.each do |reword|
            if reword.empty?
                next
            end
            if reword[0].include?('(') && reword[-1].include?(')')
                index=reword[1...-1].to_i
                insert=rezultat[index-1]
                ['.', ',', ';'].each do |punkt|
                    if insert.include? (punkt)
                        i=insert.index(punkt)
                        insert=insert[0...i]
                    end
                end
                izlaz.concat(insert)
            else
                izlaz.append(reword)
            end
        end
        return izlaz
    end
    def _sub(reci, sub)
        izlaz=[]
        reci.each do |rec|
            rec_malo=rec.downcase
            if sub.has_key?(rec_malo)
                izlaz.concat(sub[rec_malo])
            else
                izlaz.append(rec)
            end
        end
        return izlaz
    end
    def promeni_za_kraj(rec)
        if $promene.has_key?(rec.downcase)
            if $promene[rec.downcase][-1]=='m'
                return $promene[rec.downcase][0...-1]+"te"
            elsif $promene[rec.downcase][-3..-1].include? "ces"
                return $promene[rec.downcase][0..-3]+"u"
            elsif $promene[rec.downcase][-1]=='u'
                return $promene[rec.downcase][0...-1]+"ete"
            elsif $promene[rec.downcase][-1]=='s'
                return $promene[rec.downcase][0...-1]+"m"
            elsif rec.downcase.include?("moj") || rec.downcase.include?("tvoj")
                return @posts[$promene[rec.downcase]]
            else
                return $promene[rec.downcase]
            end
        end
        return rec
    end
    def _uparivanje_kljuceva(reci, kljuc)

        kljuc.decomps.each do |decomp|
            rezultat=_uparivanje(decomp.parts, reci)
            if rezultat.nil?
                next
            end
            
            rezultat=rezultat.map { |rez| _sub(rez, @posts) }
            
            reasmb=_spajanje_s(decomp)
            if reasmb[0].include?('goto')
                goto_key=reasmb[1]
                return _uparivanje_kljuceva(reci, @keys[goto_key])
            end
            izlaz=_spajanje(reasmb, rezultat)
            if decomp.save
                @memory.append(izlaz)
                next
            end
            izlaz=izlaz.map {|i| promeni_za_kraj(i)}
            return izlaz
        end
        return nil
    end

    def _gsub(rec,glagol)
        glagol.each do |k,v|
            v.each do |oblik|
                o=oblik.split(" ")
                if o.size!=1
                    o.each do |o1|
                        if rec.downcase==o1
                            $promene[k]=rec.downcase
                            return k
                        end
                    end
                end
                if rec[-1]=='m' || rec[-1]=='s'
                    if oblik==rec[0...-1].downcase
                        $promene[k]=rec.downcase
                        return k
                    end
                else
                    if oblik==rec.downcase
                        $promene[k]=rec.downcase
                        return k
                    end
                end
            end
        end
        return rec
    end
    def _psub(rec,pridevi)
        pridevi.each do |k,v|
            if v.include?(rec.downcase)
                $promene[k]=rec.downcase
                return k
            end
        end
        return rec
    end
    def odgovor(text)
        if @quits.include? (text.downcase)
            return nil
        end
        
        text.gsub!(/\s*(\.)+\s*/, ".")
        text.gsub!(/\s*,+\s*/, ",")
        text.gsub!(/\s*;+\s*/, ";")
        reci=[]
        text=text.split(' ')
        text.each do |t|
            if !t.empty?
                reci.append(t)
            end
        end    
        
        reci=reci.map {|rec| _gsub(rec,@glagoli)}
        reci=reci.map {|rec| _psub(rec,@pridevi)}
        reci=_sub(reci, @pres)
        kljucevi=[]
        reci.each do |k|
            if @keys.has_key?(k.downcase)
                kljucevi.append(@keys[k.downcase])
            end
        end
        kljucevi=kljucevi.sort_by{ |h| -h.tezina}
        
        izlaz=[]
        kljucevi.each do |k|
            izlaz=_uparivanje_kljuceva(reci, k)
            if !izlaz.nil?
                break
            end
        end
        if izlaz==[]
            if @memory!=[]
                index=rand(0...@memory.length)
                izlaz=@memory[index]
                @memory.delete_at(index)
            else
                izlaz=_spajanje_s(@keys['xnone'].decomps[0])
            end
        end
        return izlaz.join(" ")

    end
    def inicijalizuj()
        @initials.sample
    end
    def finalizuj()
        @finals.sample
    end
    
end


$selena=nil
class Gui < FXMainWindow
    def initialize(app)
        super(app, "Selena", :width=>600, :height=>650)
        
        h1= FXHorizontalFrame.new(self)
        h1.backColor=FXRGB(255, 255, 153)

        lbl1=FXLabel.new(h1, "                                              ")

        lbl1.textColor=FXRGB(255, 255, 153)
        lbl1.backColor=FXRGB(255, 255, 153)
        
        novaKonverzacija=FXButton.new(h1, "Engleski jezik")
     
        novaKonverzacija.textColor=FXRGB(255, 102, 102)
        novaKonverzacija.backColor=FXRGB(255, 230, 153)
        novaKonverzacija.shadowColor=FXRGB(255, 204, 153)
        novaKonverzacija.borderColor=FXRGB(255, 204, 153)

        srpski=FXButton.new(h1, "Srpski jezik")



        srpski.textColor=FXRGB(255, 102, 102)

        srpski.backColor=FXRGB(255, 230, 153)

        srpski.shadowColor=FXRGB(255, 204, 153)

        srpski.borderColor=FXRGB(255, 204, 153)        
        
        
        v1= FXVerticalFrame.new(self, :opts => LAYOUT_FILL)

        v1.backColor=FXRGB(255,255,153)

        $chat=FXText.new(v1, :opts=> TEXT_WORDWRAP | LAYOUT_FILL| TEXT_READONLY)

        $chat.cursorColor=FXRGB(255, 102, 102)
        $chat.textColor=FXRGB(255, 102, 102)
        $chat.backColor=FXRGB(255, 255, 255)
      
        

        h2= FXHorizontalFrame.new(v1)

        h2.backColor=FXRGB(255 ,255, 153)

        lbl2=FXLabel.new(h2, "Unesite tekst:")
        
        lbl2.backColor=FXRGB(255, 255, 153)
        lbl2.textColor = FXRGB(255, 102, 102)
        
        $input=FXTextField.new(h2, 50)

        $input.cursorColor=FXRGB(255, 102, 102)
        $input.textColor=FXRGB(255, 102, 102)
        $input.backColor=FXRGB(230, 255, 230)        

        posalji=FXButton.new(h2,"Posalji")

        posalji.textColor=FXRGB(255, 102, 102)
        posalji.backColor=FXRGB(255, 230, 153)
        posalji.shadowColor=FXRGB(255, 204, 153)
        posalji.borderColor=FXRGB(255, 204, 153)

        novaKonverzacija.connect(SEL_COMMAND) do
            $chat.removeText(0, $chat.length)
            $selena=Selena.new()
            $selena.ucitaj("doctor.txt")
            $chat.appendText("Selena>> ")
            $chat.appendText($selena.inicijalizuj())
            $chat.appendText("\n")
        end

        posalji.connect(SEL_COMMAND) do
            tekst=$input.text 
            $chat.appendText(tekst)
            $chat.appendText("\n")
            izlaz=$selena.odgovor(tekst)
            if izlaz.nil?
                $chat.appendText("Selena>> ")
                $chat.appendText($selena.finalizuj())
                $chat.appendText("\n")
            else
                $chat.appendText("Selena>> ")
                $chat.appendText(izlaz)
                $chat.appendText("\n")
            end
        end
        srpski.connect(SEL_COMMAND) do

            $chat.removeText(0, $chat.length) 

            $Srpski=1

            $selena=Selena.new()
            $selena.ucitaj("pass.txt")
            $chat.appendText("Selena>> ")
            $chat.appendText($selena.inicijalizuj())
            $chat.appendText("\n")
        end
    end

    def create
        super
        show(PLACEMENT_SCREEN)
    end
end

app=FXApp.new
gui=Gui.new(app)

gui.backColor=FXRGB(255, 255, 153)

$chat.appendStyledText("Ako zelite da pricate sa psihologom na srpskom jeziku pritisnite dugme Srpski jezik \n") 
$chat.appendText("\nAko zelite da pricate sa psihologom na engleskom jeziku pritisnite dugme Engleski jezik \n")

app.create
app.run
