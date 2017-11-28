require_relative 'compilator/version'

require 'druzy/mvc'
require 'tk'
require 'tkextlib/tile'

module Compilator
  
  class Compilator < Druzy::MVC::Controller
    
    def initialize(model = nil)
      if model == nil
        initialize(CompilatorModel.new)  
      else
        super(model)
        add_view(CompilatorView.new(self))
      end
      
    end
    
    def notify_action(view,action,kwargs={})
      if kwargs[:location] == @model.calculatrice
        
        if action == :key_pressed || action == :button_pressed
          @model.last_key_pressed = kwargs[:key]
        
        elsif action == :key_enter_pressed
          notify_action(view,:button_equal_pressed,kwargs)
          
        elsif action == :key_delete_pressed
          @model.delete = true
                
        elsif action == :button_equal_pressed
          numerateur = 0
          kwargs[:value].each_char do |c|
            numerateur = numerateur+model.score[c]
          end
          denominateur = kwargs[:value].size*5
          @model.result = numerateur.to_s+"/"+denominateur.to_s+" => "+(numerateur*20.to_f/denominateur).round(2).to_s+"/20"
          
        elsif action == :button_raz_pressed
          @model.raz = true
        end
        
      elsif kwargs[:location] == @model.total
        if action == :button_calcul_pressed
          num = kwargs['a'].to_f+kwargs['c'].to_f+kwargs['e'].to_f+kwargs['g'].to_f+kwargs['i'].to_f
          denom = kwargs['b'].to_f+kwargs['d'].to_f+kwargs['f'].to_f+kwargs['h'].to_f+kwargs['j'].to_f
          @model.result_total = num.to_s+"/"+denom.to_s
          @model.result_arrondi = (num*20.to_f/denom).round(2).to_s+'/20'
        
        elsif action == :key_enter_pressed
          notify_action(view,:button_calcul_pressed,kwargs)
        
        elsif action == :button_raz_pressed
          @model.raz_total = true
        end          
      end  
      if action == :close_window 
        view.close
      end 
    end
  end
  
  class CompilatorModel < Druzy::MVC::Model
    
    attr_accessor :score, :last_key_pressed, :result, :delete, :calculatrice, :total
    
    
    def initialize
      super()
      @score = {'r' => 0, 'o' => 1, 'j' => 2.5, 'c' => 4, 'v' => 5}
      @last_key_pressed = nil
      @result = nil
      @raz = false
      @delete = false
      @result_total = nil
      @result_arrondi = nil
      @raz_total
    end
    
    def last_key_pressed=(last_key_pressed)
      old, @last_key_pressed = @last_key_pressed, last_key_pressed
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,"last_key_pressed",old,@last_key_pressed))
    end
    
    def result=(result)
      old, @result = @result, result
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,"result",old,@result))
    end
    
    def raz=(raz)
      old, @raz = @raz, raz
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,"raz",old,@raz))
    end
    
    def delete=(delete)
      old, @delete = @delete, delete
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,'delete',old,@delete))
    end
    
    def result_total=(result_total)
      old, @result_total = @result_total, result_total
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,'result_total',old,@result_total))
    end
    
    def result_arrondi=(result_arrondi)
      old, @result_arrondi = @result_arrondi, result_arrondi
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,'result_arrondi',old,@result_arrondi))
    end
    
    def raz_total=(raz_total)
      old, @raz_total = @raz_total, raz_total
      fire_property_change(Druzy::MVC::PropertyChangeEvent.new(self,'raz_total',old,@raz_total))
    end
  end
  
  class CompilatorView < Druzy::MVC::View
  
    def initialize(controller)
      super(controller)
      
      @root = TkRoot.new
      @root.title = 'Compilator'
      @root.bind('Key') do |event|
        val = event.valid_fields['keysym'].downcase
        if val == 'return'
          Thread.new do
            @controller.notify_action(self, :key_enter_pressed, {:value => @entry_variable.value, :location => @notebook.selected}.merge(Hash[('a'..'j').collect{|el| [el,instance_variable_get("@entry_variable_"+el)]}]))
          end
          
        elsif val == 'escape'
          Thread.new do
            @controller.notify_action(self, :button_raz_pressed, :location => @notebook.selected)
          end
          
        elsif val == 'delete'
          Thread.new do
            @controller.notify_action(self, :key_delete_pressed, :location => @notebook.selected)
          end
          
        elsif @controller.model.score.has_key?(val)
          Thread.new do
            @controller.notify_action(self,:key_pressed, :key => val, :location => @notebook.selected)
          end  
        end
        
      end

      @notebook = Tk::Tile::Notebook.new(@root) do
        place('x' => 0, 'y' => 0)
      end      
      
      @window_calc = Tk::Tile::Frame.new(@notebook)
      @controller.model.calculatrice = @window_calc
      
      @font_button = TkFont.new("size" => 24)
      
      @entry_variable = TkVariable.new
      @entry = Tk::Tile::Entry.new(@window_calc)
      @entry.justify = 'right'
      @entry.validate = 'key'
      @entry.textvariable = @entry_variable
      @entry.validatecommand do |valid|
        false        
      end
      
      @controller.model.score.keys.each do |key|
        var_name = "@button_"+key
        instance_variable_set(var_name.to_sym,Tk::Tile::Button.new(@window_calc))
        button = instance_variable_get(var_name.to_sym)
        button['text'] = key.upcase
        button['width'] = 1
        button.bind('ButtonPress') do
          Thread.new do
            @controller.notify_action(self,:button_pressed, :key => key, :location => @notebook.selected)
          end
        end
      end
            
      Tk::Tile::Style.configure('Red.TButton', {"foreground" => 'red', 'font' => @font_button})
      @button_r['style'] = 'Red.TButton'
            
      Tk::Tile::Style.configure('Orange.TButton', {"foreground" => 'orange', 'font' => @font_button})
      @button_o['style'] = 'Orange.TButton'
      
      Tk::Tile::Style.configure('Yellow.TButton', {"foreground" => 'yellow', 'font' => @font_button})
      @button_j['style'] = 'Yellow.TButton'
      
      Tk::Tile::Style.configure('Lime.TButton', {"foreground" => 'lime green', 'font' => @font_button})
      @button_c['style'] = 'Lime.TButton'
      
      Tk::Tile::Style.configure('Green.TButton', {"foreground" => 'green', 'font' => @font_button})
      @button_v['style'] = 'Green.TButton'
      
      @button_raz = Tk::Tile::Button.new(@window_calc)
      @button_raz['text'] = 'RàZ'
      @button_raz['width'] = 1
      Tk::Tile::Style.configure('Medium.TButton', {'font' => TkFont.new('size' => 12)})
      @button_raz['style'] = 'Medium.TButton'
      @button_raz.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_raz_pressed)
        end
      end
      
      @button_equal = Tk::Tile::Button.new(@window_calc)
      @button_equal['text'] = '='
      Tk::Tile::Style.configure('Big.TButton', {'font' => TkFont.new('size' => 24)})
      @button_equal['style'] = 'Big.TButton'
      @button_equal['width'] = 1
      @button_equal.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_equal_pressed, :value => @entry_variable.value)
        end
      end
      
      @label_result = Tk::Tile::Label.new(@window_calc)
      @label_result.justify = 'right'
      Tk::Tile::Style.configure('Big.TLabel',{'font' => TkFont.new('size' => 14)})
      @label_result['style'] = 'Big.TLabel'

      #onglet total
      
      @window_total = Tk::Tile::Frame.new(@notebook)
      @controller.model.total = @window_total
     
      @paned_fraction = Tk::Tile::Paned.new(@window_total)
     
      {'co' => ['a','b'], 'ce' => ['c','d'], 'ee' => ['e','f'], 'eoc' => ['g','h'], 'eoi'=> ['i','j']}.each do |key,value|
        label_name = "@label_frame_"+key
        instance_variable_set(label_name.to_sym,Tk::Tile::Labelframe.new(@paned_fraction))
        label_frame = instance_variable_get(label_name.to_sym)
        label_frame['text'] = key.upcase
        
        value.each do |val|
          entry_name = "@entry_"+val
          entry_variable_name = "@entry_variable_"+val
          instance_variable_set(entry_name.to_sym,Tk::Tile::Entry.new(label_frame))
          instance_variable_set(entry_variable_name.to_sym,TkVariable.new)
          entry = instance_variable_get(entry_name.to_sym)
          entry_variable = instance_variable_get(entry_variable_name.to_sym)
          
          entry.width = 3
          entry.textvariable = entry_variable
          entry.validate = 'key'
          entry.validatecommand do |valid|
            if (0..9).map{|el| el.to_s}.include?(valid.string)
              true
            elsif valid.string=='.'
              true
            else
              false
            end
          end   
        end        
        
      end
      
      @paned_result = Tk::Tile::Paned.new(@window_total)
      
      @label_frame_brut = Tk::Tile::Labelframe.new(@paned_result)
      @label_frame_brut['text'] = 'Résultat brut'
      
      @label_result_brut = Tk::Tile::Label.new(@label_frame_brut)
      @label_result_brut['text'] = '0'
      @label_result_brut.justify = 'right'
      
      @label_frame_arrondi = Tk::Tile::Labelframe.new(@paned_result)
      @label_frame_arrondi['text'] = "Résultat arrondi au centième"
      
      @label_result_arrondi = Tk::Tile::Label.new(@label_frame_arrondi)
      @label_result_arrondi['text'] = '0'
      @label_result_arrondi.justify = 'right'
            
      @paned_button = Tk::Tile::Paned.new(@window_total)
      
      for n in (0..9)
        var_name = "@button_"+n.to_s
        instance_variable_set(var_name.to_sym,Tk::Tile::Button.new(@paned_button))
        button = instance_variable_get(var_name.to_sym)
        button['text'] = n.to_s
        button['style'] = 'Big.TButton'
        button['width'] = 1
      end
      
      @button_raz_total = Tk::Tile::Button.new(@paned_button)
      @button_raz_total['text'] = 'RàZ'
      @button_raz_total.bind('ButtonPress') do
        puts "rrrr"
        Thread.new do
          @controller.notify_action(self,:button_raz_pressed, :location => @notebook.selected)
        end
      end
      
      @button_del = Tk::Tile::Button.new(@paned_button)
      @button_del['text'] = 'Del/Suppr'
      
      @button_calcul = Tk::Tile::Button.new(@paned_button)
      @button_calcul['text'] = 'Calculer'
      @button_calcul.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_calcul_pressed, {:location => @notebook.selected}.merge(Hash[('a'..'j').collect{|el| [el,instance_variable_get("@entry_variable_"+el)]}]))
        end
      end
      #ajout
     
      TkGrid.columnconfigure( @root, 0, :weight => 1 )
      TkGrid.rowconfigure( @root, 0, :weight => 1 )
      
      TkGrid.columnconfigure( @window_calc, 0, :weight => 1)
      TkGrid.columnconfigure( @window_calc, 1, :weight => 1 )
      TkGrid.columnconfigure( @window_calc, 2, :weight => 1 )
      TkGrid.rowconfigure( @window_calc, 0, :weight => 0)
      TkGrid.rowconfigure( @window_calc, 1, :weight => 1)
      TkGrid.rowconfigure( @window_calc, 2, :weight => 1)
      TkGrid.rowconfigure( @window_calc, 3, :weight => 1)
      TkGrid.rowconfigure( @window_calc, 4, :weight => 0)
      
      TkGrid.columnconfigure(@window_total,0, :weight => 1)
      TkGrid.rowconfigure(@window_total, 0, :weight => 0)
      TkGrid.rowconfigure(@window_total, 1, :weight => 0)
      TkGrid.rowconfigure(@window_total, 2, :weight => 1)
      
      TkGrid.columnconfigure(@paned_fraction, 0, :weight =>1)
      TkGrid.columnconfigure(@paned_fraction, 1, :weight =>1)
      TkGrid.columnconfigure(@paned_fraction, 2, :weight =>1)
      TkGrid.columnconfigure(@paned_fraction, 3, :weight =>1)
      TkGrid.columnconfigure(@paned_fraction, 4, :weight =>1)
      
      TkGrid.columnconfigure(@paned_result, 0, :weight =>1)
      TkGrid.columnconfigure(@paned_result, 1, :weight =>1)
      
      @notebook.add(@window_calc, :text => 'Calculatrice')
      @notebook.add(@window_total, :text => 'Total')
      @notebook.grid(:column => 0, :row => 0, :sticky => 'nsew')      
      
      @entry.grid(:column => 0, :row => 0, :columnspan => 3, :sticky => 'new')

      @button_r.grid(:column => 0, :row => 1, :sticky => 'nsew')
      @button_o.grid(:column => 1, :row => 1, :sticky => 'nsew')
      @button_j.grid(:column => 2, :row => 1, :sticky => 'ewns')
      @button_c.grid(:column => 0, :row => 2, :sticky => 'ewns')
      @button_v.grid(:column => 1, :row => 2, :sticky => 'ewns')
      @button_raz.grid(:column => 0, :row => 3, :sticky => 'ewns')
      @button_equal.grid(:column => 1, :row => 3, :columnspan => 2, :sticky => 'ewns')
      
      
      @label_result.grid(:column => 0, :row => 4, :columnspan => 3, :sticky => 'ews')
      
      @paned_fraction.grid(:column => 0, :row => 0, :sticky => 'ew')
      
      @label_frame_co.grid(:column => 0, :row => 0)
      @entry_a.grid(:column => 0, :row => 0)
      @entry_b.grid(:column => 0, :row => 1)
      
      @label_frame_ce.grid(:column => 1, :row => 0)
      @entry_c.grid(:column => 0, :row => 0)
      @entry_d.grid(:column => 0, :row => 1)
      
      @label_frame_ee.grid(:column => 2, :row => 0)
      @entry_e.grid(:column => 0, :row => 0)
      @entry_f.grid(:column => 0, :row => 1)
      
      @label_frame_eoc.grid(:column => 3, :row => 0)
      @entry_g.grid(:column => 0, :row => 0)
      @entry_h.grid(:column => 0, :row => 1)
      
      @label_frame_eoi.grid(:column => 4, :row => 0)
      @entry_i.grid(:column => 0, :row => 0)
      @entry_j.grid(:column => 0, :row => 1)      
      
      @paned_result.grid(:column => 0, :row => 1, :sticky => 'ew')
      @label_frame_brut.grid(:column => 0, :row => 0, :sticky => 'ew')
      @label_result_brut.grid(:column => 0, :row => 0, :sticky => 'ew')
      
      @label_frame_arrondi.grid(:column => 1, :row => 0, :sticky => 'ew')
      @label_result_arrondi.grid(:column => 0, :row => 0, :sticky => 'ew')
      
      @paned_button.grid(:column => 0, :row => 2)
      @button_raz_total.grid(:column => 0, :row => 0)
      @button_del.grid(:column => 0, :row => 1)
      @button_calcul.grid(:column => 0, :row => 2, :columnspan => 6, :sticky => 'ew' )
      for n in (0..4) do
        button1 = instance_variable_get("@button_"+n.to_s)
        button2 = instance_variable_get("@button_"+(n+5).to_s)
        button1.grid(:column => n+1, :row => 0)
        button2.grid(:column => n+1, :row => 1)
      end
      
    end
    
    def display
    end
    
    def close
    end
  
    def property_change(event)
      if event.property_name == "last_key_pressed"
        Thread.new do
          @entry_variable.set_value(@entry_variable.value+event.new_value)
        end
        
      elsif event.property_name == 'result'
        Thread.new do
          @label_result.text = event.new_value.to_s 
        end
        
      elsif event.property_name == 'raz'
        Thread.new do
          @entry_variable.set_value('')
        end
        
      elsif event.property_name == 'delete'
        Thread.new do
          @entry_variable.set_value(@entry_variable.value[0..-2])
        end
        
      elsif event.property_name == 'result_total'
        Thread.new do
          @label_result_brut.text = event.new_value.to_s
        end
        
      elsif event.property_name == 'result_arrondi'
        Thread.new do
          @label_result_arrondi.text = event.new_value.to_s
        end
        
      elsif event.property_name == 'raz_total'
        puts "coucou"
        Thread.new do
          ('a'..'j').each do |el|
            
            instance_variable_get("@entry_variable_"+el).set_value('')
          end
        end
      end
    end
  
  end
  
end

Compilator::Compilator.new.display_views

Tk.mainloop
