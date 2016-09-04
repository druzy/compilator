require_relative 'compilator/version'

require 'druzy/mvc'
require 'gtk3'

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
      
      @window = Gtk::Window.new
      @window.title = 'COMPILATOR'
      @window.signal_connect('key_press_event') do |widget, event|
        val = Gdk::Keyval.name(Gdk::Keyval.to_lower(event.keyval))
        
        if controller.model.score.has_key?(val)
          Thread.new do
            controller.notify_action(self,:key_pressed, :key => val)
          end
          
        elsif event.keyval == Gdk::Keyval::KEY_Return
          Thread.new do
            controller.notify_action(self, :key_enter_pressed, :value => @entry.text)
          end
        end
      end
      @window.signal_connect('delete-event') do 
        Thread.new do
          controller.notify_action(self,:close_window)
        end
      end
      
      @entry = Gtk::Entry.new
      @entry.editable = false
      @entry.xalign = 1
      
      @button_r = Gtk::Button.new
      @button_r.add(Gtk::Label.new.set_markup('<span size="xx-large" foreground="red">R</span>'))
      @button_r.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_pressed, :key => 'r')
        end
      end

      @button_o = Gtk::Button.new
      @button_o.add(Gtk::Label.new.set_markup('<span size="xx-large" foreground="orange">O</span>'))
      @button_o.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_pressed, :key => 'o')
        end
      end

      @button_j = Gtk::Button.new
      @button_j.add(Gtk::Label.new.set_markup('<span size="xx-large" foreground="yellow">J</span>'))
      @button_j.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_pressed, :key => 'j')
        end
      end

      @button_c = Gtk::Button.new
      @button_c.add(Gtk::Label.new.set_markup('<span size="xx-large" foreground="lime">C</span>'))
      @button_c.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_pressed, :key => 'c')
        end
      end

      @button_v = Gtk::Button.new
      @button_v.add(Gtk::Label.new.set_markup('<span size="xx-large" foreground="green">V</span>'))
      @button_v.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_pressed, :key => 'v')
        end
      end

      @button_e = Gtk::Button.new
      @button_e.add(Gtk::Label.new.set_markup('<span underline="single" size="xx-large" foreground="green">E</span>'))
      @button_e.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_pressed, :key => 'e')
        end
      end

      @button_equal = Gtk::Button.new(:label => '=')
      @button_equal.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_equal_pressed, :value => @entry.text)
        end
      end
      
      @button_raz = Gtk::Button.new(:label => "RàZ")
      @button_raz.signal_connect("clicked") do
        Thread.new do
          controller.notify_action(self,:button_raz_pressed)
        end
      end
      
      @label_result = Gtk::Label.new("0")
      @label_result.xalign = 1
      
      #container
      @onglet = Gtk::Notebook.new
       
      @main_vbox = Gtk::Box.new(:vertical, 0)
      
      @grid_button = Gtk::Grid.new
      @grid_button.set_property("row_homogeneous",true)
      @grid_button.set_property("column-homogeneous", true)
      
      #ajout
      @onglet.append_page(@main_vbox, Gtk::Label.new("Calculatrice"))
      
      @window.add(@onglet)
      
      @main_vbox.pack_start(@entry, :expand => false)
      @main_vbox.pack_start(@grid_button,:expand => true, :fill => true, :padding => 10)
      @main_vbox.pack_start(@label_result, :expand => false, :padding => 10)
      
      @grid_button.attach(@button_r,0,0,1,1,)
      @grid_button.attach(@button_o,1,0,1,1)
      @grid_button.attach(@button_j,2,0,1,1)
      @grid_button.attach(@button_c,0,1,1,1)
      @grid_button.attach(@button_v,1,1,1,1)
      @grid_button.attach(@button_e,2,1,1,1)
      @grid_button.attach(@button_raz,0,2,1,1)
      @grid_button.attach(@button_equal,1,2,2,1)
    end
    
    def display
      @window.show_all
    end
    
    def close
      @window.destroy
      Gtk.main_quit
    end
  
    def property_change(event)
      if event.property_name == "last_key_pressed"
        @entry.text = @entry.text+event.new_value
        
      elsif event.property_name == 'result'
        @label_result.text = event.new_value.to_s 
        
      elsif event.property_name == 'raz'
        @entry.text = ''
      end
    end
  
  end
  
end

Gtk.init
Thread.new do
  Gtk.main
end

Compilator::Compilator.new.display_views

Thread.list.each {|t| t.join if t!=Thread.main}