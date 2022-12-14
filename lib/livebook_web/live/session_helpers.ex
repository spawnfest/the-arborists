defmodule LivebookWeb.SessionHelpers do
  import Phoenix.LiveView

  alias Phoenix.LiveView.Socket
  alias Livebook.Session
  alias LivebookWeb.Router.Helpers, as: Routes

  @doc """
  Creates a new session, redirects on success,
  puts an error flash message on failure.

  Accepts the same options as `Livebook.Sessions.create_session/1`.
  """
  @spec create_session(Socket.t(), keyword()) :: Socket.t()
  def create_session(socket, opts \\ []) do
    # Revert persistence options to default values if there is
    # no file attached to the new session
    opts =
      if opts[:notebook] != nil and opts[:file] == nil do
        Keyword.update!(opts, :notebook, &Livebook.Notebook.reset_persistence_options/1)
      else
        opts
      end

    case Livebook.Sessions.create_session(opts) do
      {:ok, session} ->
        redirect_path = session_path(socket, session.id, opts)
        push_redirect(socket, to: redirect_path)

      {:error, reason} ->
        put_flash(socket, :error, "Failed to create session: #{reason}")
    end
  end

  @doc """
  Generate the session path based on the provided options.
  """
  @spec session_path(Socket.t(), Session.id(), keyword()) :: String.t()
  def session_path(socket, session_id, opts \\ []) do
    socket
    |> Routes.session_path(:page, session_id)
    |> maybe_add_url_hash(opts)
  end

  defp maybe_add_url_hash(redirect_path, opts) do
    case opts[:url_hash] do
      nil -> redirect_path
      url_hash -> "#{redirect_path}##{url_hash}"
    end
  end

  @doc """
  Formats the given list of notebook import messages and puts
  into the warning flash.
  """
  @spec put_import_warnings(Socket.t(), list(String.t())) :: Socket.t()
  def put_import_warnings(socket, messages)

  def put_import_warnings(socket, []), do: socket

  def put_import_warnings(socket, messages) do
    list =
      messages
      |> Enum.map(fn message -> ["- ", message] end)
      |> Enum.intersperse("\n")

    flash =
      IO.iodata_to_binary([
        "We found problems while importing the file and tried to autofix them:\n" | list
      ])

    put_flash(socket, :warning, flash)
  end

  def uses_memory?(%{runtime: %{total: total}}) when total > 0, do: true
  def uses_memory?(_), do: false
end
