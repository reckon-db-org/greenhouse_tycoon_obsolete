defmodule GreenhouseTycoonWeb.ThemeToggleComponent do
  use GreenhouseTycoonWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="toggle_theme"
      phx-target={@myself}
      class="inline-flex items-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700 dark:hover:text-gray-300 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-green-500 transition-colors duration-200"
      aria-label="Toggle theme"
    >
      <svg
        :if={@theme == "light"}
        class="h-5 w-5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="2"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
        />
      </svg>
      <svg
        :if={@theme == "dark"}
        class="h-5 w-5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="2"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
        />
      </svg>
    </button>
    """
  end

  @impl true
  def handle_event("toggle_theme", _params, socket) do
    current_theme = socket.assigns.theme
    new_theme = GreenhouseTycoonWeb.ThemeManager.toggle_theme(current_theme)
    
    # Send message to parent LiveView to update theme
    send(self(), {:theme_changed, new_theme})
    
    {:noreply, assign(socket, :theme, new_theme)}
  end
  
  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
