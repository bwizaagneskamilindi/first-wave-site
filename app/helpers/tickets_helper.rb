module TicketsHelper
  # Draws a QR code as an inline SVG image. The text is our own ticket code, so it is safe.
  def qr_svg(text)
    svg = RQRCode::QRCode.new(text.to_s, level: :m).as_svg(
      color: "3a0818",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      use_path: true,
      viewbox: true
    )
    raw(svg)
  end
end
