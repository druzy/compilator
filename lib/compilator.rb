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
      
      if action == :key_pressed || action == :button_pressed
        model.last_key_pressed = kwargs[:key]
      
      elsif action == :key_enter_pressed
        notify_action(view,:button_equal_pressed,kwargs)
              
      elsif action == :button_equal_pressed
        numerateur = 0
        kwargs[:value].each_char do |c|
          numerateur = numerateur+model.score[c]
        end
        denominateur = kwargs[:value].size*5
        model.result = numerateur.to_s+"/"+denominateur.to_s+" => "+(numerateur*20.to_f/denominateur).round(2).to_s+"/20"
        
      elsif action == :button_raz_pressed
        model.raz = true
        
      elsif action == :close_window 
        view.close
      end 
    end
  end
  
  class CompilatorModel < Druzy::MVC::Model
    
    attr_accessor :score, :last_key_pressed, :result
    
    
    def initialize
      super()
      @score = {'r' => 0, 'o' => 1, 'j' => 2, 'c' => 3, 'v' => 4, 'e' => 5}
      @last_key_pressed = nil
      @result = nil
      @raz = false
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
  end
  
  class CompilatorView < Druzy::MVC::View
  
    def initialize(controller)
      super(controller)
      #Tk::Tile::Style.theme_use "classic"
      
      @root = TkRoot.new
      @root.title = 'Compilator'
      @root.bind('Key') do |event|
        val = event.valid_fields['keysym'].downcase
        
        if val == 'return'
          Thread.new do
            @controller.notify_action(self, :key_enter_pressed, :value => @entry_variable.value)
          end
        elsif @controller.model.score.has_key?(val)
          Thread.new do
            @controller.notify_action(self,:key_pressed, :key => val)
          end  
        end
        
      end
      
      @window = Tk::Tile::Frame.new(@root)
      
      @entry_variable = TkVariable.new
      @entry = Tk::Tile::Entry.new(@window)
      @entry.justify = 'right'
      @entry.validate = 'key'
      @entry.textvariable = @entry_variable 
      @entry.validatecommand do |valid|
        if valid.action == 1
         false
       else
         true
       end          
      end
      
      @button_r = Tk::Tile::Button.new(@window)
      @button_r['text'] = 'R'
      Tk::Tile::Style.configure('Red.TButton', {"foreground" => 'red'  })
      @button_r['style'] = 'Red.TButton'
      @button_r.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_pressed, :key => 'r')
        end
      end
            
      @button_o = Tk::Tile::Button.new(@window)
      @button_o['text'] = 'O'
      Tk::Tile::Style.configure('Orange.TButton', {"foreground" => 'orange'  })
      @button_o['style'] = 'Orange.TButton'
      @button_o.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_pressed, :key => 'o')
        end
      end
      
      @button_j = Tk::Tile::Button.new(@window)
      @button_j['text'] = 'J'
      Tk::Tile::Style.configure('Yellow.TButton', {"foreground" => 'yellow'  })
      @button_j['style'] = 'Yellow.TButton'
      @button_j.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_pressed, :key => 'j')
        end
      end
      
      @button_c = Tk::Tile::Button.new(@window)
      @button_c['text'] = 'C'
      Tk::Tile::Style.configure('Lime.TButton', {"foreground" => 'lime'  })
      @button_c['style'] = 'Lime.TButton'
      @button_c.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_pressed, :key => 'c')
        end
      end
      
      @button_v = Tk::Tile::Button.new(@window)
      @button_v['text'] = 'V'
      Tk::Tile::Style.configure('Green.TButton', {"foreground" => 'green'  })
      @button_v['style'] = 'Green.TButton'
      @button_v.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_pressed, :key => 'v')
        end
      end
      
      @button_e = Tk::Tile::Button.new(@window)
      @button_e['text'] = 'E'
      @button_e['underline'] = 0
      Tk::Tile::Style.configure('Underline.TButton', {"foreground" => 'green'})
      @button_e['style'] = 'Underline.TButton'
      @button_e.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_pressed, :key => 'e')
        end
      end
      
      @button_raz = Tk::Tile::Button.new(@window)
      @button_raz['text'] = 'RàZ'
      @button_raz.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_raz_pressed)
        end
      end
      
      @button_equal = Tk::Tile::Button.new(@window)
      @button_equal['text'] = '='
      @button_equal.bind('ButtonPress') do
        Thread.new do
          @controller.notify_action(self,:button_equal_pressed, :value => @entry_variable.value)
        end
      end
      
      @label_result = Tk::Tile::Label.new(@window)
      @label_result.justify('right')
      
      #ajout
      TkGrid.columnconfigure( @root, 0, :weight => 1 )
      TkGrid.rowconfigure( @root, 0, :weight => 1 )
      
      TkGrid.columnconfigure( @window, 0, :weight => 1)
      TkGrid.columnconfigure( @window, 1, :weight => 1 )
      TkGrid.columnconfigure( @window, 2, :weight => 1 )
      TkGrid.rowconfigure( @window, 0, :weight => 0)
      TkGrid.rowconfigure( @window, 1, :weight => 1)
      TkGrid.rowconfigure( @window, 2, :weight => 1)
      TkGrid.rowconfigure( @window, 3, :weight => 1)
      TkGrid.rowconfigure( @window, 4, :weight => 0)
      
      @window.grid(:column => 0, :row => 0, :sticky => 'nsew')
      
      @entry.grid(:column => 0, :row => 0, :columnspan => 3, :sticky => 'new')
      

      @button_r.grid(:column => 0, :row => 1, :sticky => 'nsew')
      @button_o.grid(:column => 1, :row => 1, :sticky => 'nsew')
      @button_j.grid(:column => 2, :row => 1, :sticky => 'ewns')
      @button_c.grid(:column => 0, :row => 2, :sticky => 'ewns')
      @button_v.grid(:column => 1, :row => 2, :sticky => 'ewns')
      @button_e.grid(:column => 2, :row => 2, :sticky => 'ewns')
      @button_raz.grid(:column => 0, :row => 3, :sticky => 'ewns')
      @button_equal.grid(:column => 1, :row => 3, :columnspan => 2, :sticky => 'ewns')
      
      @label_result.grid(:column => 0, :row => 4, :columnspan => 3, :sticky => 'ew')
      
    end
    
    def display
    end
    
    def close
    end
  
    def property_change(event)
      if event.property_name == "last_key_pressed"
        @entry_variable.set_value(@entry_variable.value+event.new_value)
        
      elsif event.property_name == 'result'
        
        @label_result.text = event.new_value.to_s 
        
      elsif event.property_name == 'raz'
        @entry_variable.set_value('')
      end
    end
  
  end
  
end

Compilator::Compilator.new.display_views

Tk.mainloop