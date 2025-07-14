defmodule GreenhouseTycoonWeb.ThemeManager do
  @moduledoc """
  Manages theme state and persistence across the application.
  """
  
  @default_theme "light"
  
  @doc """
  Get the theme from the session, defaulting to light theme.
  """
  def get_theme(session) do
    Map.get(session, "theme", @default_theme)
  end
  
  @doc """
  Set the theme in the session.
  """
  def set_theme(session, theme) when theme in ["light", "dark"] do
    Map.put(session, "theme", theme)
  end
  
  @doc """
  Get the default theme.
  """
  def default_theme, do: @default_theme
  
  @doc """
  Toggle between light and dark themes.
  """
  def toggle_theme("light"), do: "dark"
  def toggle_theme("dark"), do: "light"
  def toggle_theme(_), do: @default_theme
  
  @doc """
  Generate the body class for the current theme.
  """
  def body_class("dark"), do: "dark"
  def body_class(_), do: ""
  
  @doc """
  Get JavaScript code for theme initialization.
  This should be run on page load to apply the theme before the page renders.
  """
  def theme_init_js do
    """
    (function() {
      const theme = localStorage.getItem('theme') || 'light';
      if (theme === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    })();
    """
  end
  
  @doc """
  Get JavaScript code for theme persistence.
  This should be run when the theme changes.
  """
  def theme_persist_js(theme) do
    """
    localStorage.setItem('theme', '#{theme}');
    if ('#{theme}' === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    """
  end
end
