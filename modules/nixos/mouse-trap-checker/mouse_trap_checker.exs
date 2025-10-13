Mix.install([
  {:httpoison, "~> 2.0"},
  {:jason, "~> 1.4"}
])

defmodule MouseMonitor do
  use GenServer
  require Logger

  @state_dir "/var/lib/mouse-monitor"
  @reference_image Path.join(@state_dir, "reference.jpg")
  @current_image Path.join(@state_dir, "current.jpg")
  @diff_image Path.join(@state_dir, "diff.jpg")

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Logger.info("Mouse Monitor starting...")
    File.mkdir_p!(@state_dir)

    # Load config from env vars
    config = %{
      camera_url: System.get_env("CAMERA_URL") || raise("CAMERA_URL not set"),
      ha_url: System.get_env("HA_URL") || raise("HA_URL not set"),
      ha_token: System.get_env("HA_TOKEN") || raise("HA_TOKEN not set"),
      light_entity: System.get_env("LIGHT_ENTITY", "switch.mousetrap_cam_flash"),
      check_interval_ms:
        String.to_integer(System.get_env("CHECK_INTERVAL_MINUTES", "15"), 10) * 60 * 1000,
      threshold: System.get_env("DIFFERENCE_THRESHOLD", "200.0") |> String.to_float()
    }

    Logger.info(
      "Config: Camera: #{config.camera_url}, HA: #{config.ha_url}, Interval: #{div(config.check_interval_ms, 60000)} min, Threshold: #{config.threshold}"
    )

    unless File.exists?(@reference_image) do
      Logger.info("Capturing reference image...")
      capture_reference(config)
    end

    schedule_check(config.check_interval_ms)
    {:ok, config}
  end

  def handle_info(:check_trap, config) do
    try do
      check_for_mouse(config)
    rescue
      e ->
        Logger.error("Check failed: #{inspect(e)}")
    end

    schedule_check(config.check_interval_ms)
    {:noreply, config}
  end

  defp schedule_check(interval_ms) do
    Process.send_after(self(), :check_trap, interval_ms)
  end

  defp capture_reference(config) do
    image_data = capture_image_with_light(config)
    File.write!(@reference_image, image_data)
    notify(config, "Mouse trap reference image captured - verify trap is empty")
  end

  defp capture_image_with_light(config) do
    # Turn on light
    control_light(config, true)
    # Wait for exposure adjustment
    Process.sleep(8000)

    # Capture image
    response = HTTPoison.get!(config.camera_url)

    # Turn off light
    control_light(config, false)

    response.body
  end

  defp control_light(config, on) do
    service = if on, do: "turn_on", else: "turn_off"

    HTTPoison.post!(
      "#{config.ha_url}/api/services/switch/#{service}",
      Jason.encode!(%{entity_id: config.light_entity}),
      [
        {"Authorization", "Bearer #{config.ha_token}"},
        {"Content-Type", "application/json"}
      ]
    )

    Logger.debug("Light turned #{if on, do: "on", else: "off"}")
  end

  defp check_for_mouse(config) do
    Logger.info("Checking trap...")

    current_data = capture_image_with_light(config)
    File.write!(@current_image, current_data)

    # Use ImageMagick to compare
    {output, _exit_code} =
      System.cmd(
        "compare",
        [
          "-fuzz",
          "5%",
          "-metric",
          "MAE",
          @reference_image,
          @current_image,
          @diff_image
        ],
        stderr_to_stdout: true
      )

    Logger.info(output)
    difference = parse_difference(output)
    Logger.info("Difference: #{difference} (threshold: #{config.threshold})")

    if difference > config.threshold do
      handle_detection(config, difference)
    end
  end

  defp parse_difference(output) do
    case Regex.run(~r/^(\d+(?:\.\d+)?)/m, output) do
      [_, num] ->
        {float, _} = Float.parse(num)
        float

      _ ->
        Logger.warning("Could not parse difference: #{output}")
        0.0
    end
  end

  defp handle_detection(config, difference) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    alert_image = Path.join(@state_dir, "alert_#{timestamp}.jpg")

    File.copy!(@current_image, alert_image)
    Logger.warning("MOUSE DETECTED! Difference: #{difference}")

    message = "Mouse detected! Difference: #{Float.round(difference, 1)}"
    notify(config, message, :high)

    # Also create a persistent notification in HA
    HTTPoison.post!(
      "#{config.ha_url}/api/services/persistent_notification/create",
      Jason.encode!(%{
        notification_id: "mouse_trap_#{timestamp}",
        title: "🐭 Mouse in Trap!",
        message: "#{message}\nDetected at #{DateTime.utc_now()}"
      }),
      [
        {"Authorization", "Bearer #{config.ha_token}"},
        {"Content-Type", "application/json"}
      ]
    )
  end

  defp notify(config, message, priority \\ :normal) do
    HTTPoison.post!(
      "#{config.ha_url}/api/services/notify/notify",
      Jason.encode!(%{
        title: "Mouse Trap Monitor",
        message: message,
        data: %{
          priority: priority,
          tag: "mouse-trap"
        }
      }),
      [
        {"Authorization", "Bearer #{config.ha_token}"},
        {"Content-Type", "application/json"}
      ]
    )

    Logger.info("Notification sent: #{message}")
  end
end

# Start the application
defmodule MouseMonitor.Application do
  use Application

  def start(_type, _args) do
    children = [MouseMonitor]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

MouseMonitor.Application.start(:normal, [])
Process.sleep(:infinity)
