//
//  PlaylistPDFGenerator.swift
//  CycleMusicTimer2
//
//  Generates a printable PDF for a playlist's tracks, including
//  time, artist, album, track title, and drill (if any).
//  Provides a UIActivityViewController wrapper for sharing the
//  resulting PDF via the standard system share sheet.
//

import UIKit
import SwiftUI

//--------------------------------------------
struct PlaylistPDFTrack
{
  let index             : Int
  let time              : String
  let playlistTimeLabel : String   // e.g. "Elapsed" or "Remaining"
  let playlistTime      : String   // e.g. "4:30"
  let artist            : String
  let album             : String
  let title             : String
  let drill             : String?
}

//--------------------------------------------
struct PlaylistPDFGenerator
{
  //-----------------------------------------------------------
  static func generate(
    playlistName playlistNameP : String,
          tracks tracksP       : [PlaylistPDFTrack] ) -> URL?
  {
            // US Letter page size in points (8.5 x 11 inches).
    let pageRect = CGRect( x: 0, y: 0, width: 612, height: 792 )
    let margin : CGFloat = 36
    let contentWidth = pageRect.width - ( 2 * margin )
    let bottomLimit = pageRect.height - margin

    let titleFont      = UIFont.boldSystemFont( ofSize: 20 )
    let trackTitleFont = UIFont.boldSystemFont( ofSize: 14 )
    let detailFont     = UIFont.systemFont( ofSize: 12 )
    let drillFont      = UIFont.italicSystemFont( ofSize: 11 )
    let footerFont     = UIFont.systemFont( ofSize: 9 )

    let titleAttrs : [NSAttributedString.Key: Any] =
      [ .font            : titleFont,
        .foregroundColor : UIColor.black ]

    let trackTitleAttrs : [NSAttributedString.Key: Any] =
      [ .font            : trackTitleFont,
        .foregroundColor : UIColor.black ]

    let detailAttrs : [NSAttributedString.Key: Any] =
      [ .font            : detailFont,
        .foregroundColor : UIColor.darkGray ]

    let drillAttrs : [NSAttributedString.Key: Any] =
      [ .font            : drillFont,
        .foregroundColor : UIColor.systemRed ]

    let footerAttrs : [NSAttributedString.Key: Any] =
      [ .font            : footerFont,
        .foregroundColor : UIColor.gray ]

            // Build a safe filename from the playlist name.
    let invalid = CharacterSet( charactersIn: "/\\:*?\"<>|" )
    let cleaned = playlistNameP
                    .components( separatedBy: invalid )
                    .joined( separator: "_" )
    let baseName = cleaned.isEmpty ? "Playlist" : cleaned
    let tempURL  = FileManager.default.temporaryDirectory
                     .appendingPathComponent( "\(baseName).pdf" )

            // Remove any prior file with this name.
    try? FileManager.default.removeItem( at: tempURL )

    let renderer = UIGraphicsPDFRenderer( bounds: pageRect )

    do
    {
      try renderer.writePDF( to: tempURL )
      { context in

        context.beginPage()
        var yPos : CGFloat = margin

            // Title

        let titleString = NSAttributedString(
                            string: playlistNameP,
                        attributes: titleAttrs )
        let titleBR = titleString.boundingRect(
                        with: CGSize( width: contentWidth,
                                     height: .greatestFiniteMagnitude ),
                     options: [ .usesLineFragmentOrigin, .usesFontLeading ],
                     context: nil )
        titleString.draw(
          in: CGRect( x: margin, y: yPos,
                  width: contentWidth, height: titleBR.height ) )
        yPos += titleBR.height + 4

            // Printed date subtitle

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = NSAttributedString(
                           string: "Printed: \(dateFormatter.string(from: Date()))",
                       attributes: footerAttrs )
        let dateBR = dateString.boundingRect(
                       with: CGSize( width: contentWidth,
                                    height: .greatestFiniteMagnitude ),
                    options: [ .usesLineFragmentOrigin, .usesFontLeading ],
                    context: nil )
        dateString.draw(
          in: CGRect( x: margin, y: yPos,
                  width: contentWidth, height: dateBR.height ) )
        yPos += dateBR.height + 8

            // Top separator line

        drawHorizontalLine(
          from: CGPoint( x: margin, y: yPos ),
            to: CGPoint( x: pageRect.width - margin, y: yPos ),
         color: .black,
         width: 1 )
        yPos += 10

            // Each track

            // Right-aligned paragraph style for label column.
        let rightAlignStyle = NSMutableParagraphStyle()
        rightAlignStyle.alignment = .right

        var labelAttrs = detailAttrs
        labelAttrs[.paragraphStyle] = rightAlignStyle

        for track in tracksP
        {
            // Header: item number, song time, then title (bold).
          let header = "\(track.index). [\(track.time)]  \(track.title)"

          let headerStr = NSAttributedString( string: header,
                                          attributes: trackTitleAttrs )

          let headerBR = headerStr.boundingRect(
                           with: CGSize( width: contentWidth,
                                        height: .greatestFiniteMagnitude ),
                        options: [ .usesLineFragmentOrigin, .usesFontLeading ],
                        context: nil )

            // Build label/value pairs for the labeled detail lines.
            // Track which rows use the drill (red italic) value style.
          var labels : [String] = [ "\(track.playlistTimeLabel):",
                                    "Artist:",
                                    "Album:" ]
          var values : [String] = [ track.playlistTime,
                                    track.artist,
                                    track.album ]
          var valueAttrsList : [[NSAttributedString.Key: Any]] =
                [ detailAttrs, detailAttrs, detailAttrs ]

          if let drill = track.drill, !drill.isEmpty
          {
            labels.append( "Drill:" )
            values.append( drill )
            valueAttrsList.append( drillAttrs )
          }

            // Width of the widest label, used to align the colons.
            // All labels are measured with the same font so colons
            // line up exactly.
          var maxLabelWidth : CGFloat = 0
          for label in labels
          {
            let lStr = NSAttributedString( string: label,
                                       attributes: detailAttrs )
            let lBR = lStr.boundingRect(
                        with: CGSize( width: contentWidth,
                                     height: .greatestFiniteMagnitude ),
                     options: [ .usesLineFragmentOrigin, .usesFontLeading ],
                     context: nil )
            if lBR.width > maxLabelWidth { maxLabelWidth = lBR.width }
          }

          let labelGap   : CGFloat = 6
          let labelX     = margin + 16
          let valueX     = labelX + maxLabelWidth + labelGap
          let valueWidth = pageRect.width - margin - valueX

            // Pre-compute heights for each detail row using the value's
            // own attributes (drill row may wrap differently).
          var rowHeights : [CGFloat] = []
          for i in values.indices
          {
            let vStr = NSAttributedString( string: values[ i ],
                                       attributes: valueAttrsList[ i ] )
            let vBR = vStr.boundingRect(
                        with: CGSize( width: valueWidth,
                                     height: .greatestFiniteMagnitude ),
                     options: [ .usesLineFragmentOrigin, .usesFontLeading ],
                     context: nil )
            rowHeights.append( vBR.height )
          }

          let detailsHeight = rowHeights.reduce( 0, + ) +
                              CGFloat( rowHeights.count ) * 2
          let totalHeight = headerBR.height + detailsHeight + 18

            // Page break if the row would overflow.

          if yPos + totalHeight > bottomLimit
          {
            context.beginPage()
            yPos = margin
          }

          headerStr.draw(
            in: CGRect( x: margin, y: yPos,
                    width: contentWidth, height: headerBR.height ) )
          yPos += headerBR.height + 2

            // Draw each labeled detail line.
          for i in labels.indices
          {
            let rowH = rowHeights[ i ]

            let lStr = NSAttributedString( string: labels[ i ],
                                       attributes: labelAttrs )
            lStr.draw(
              in: CGRect( x: labelX, y: yPos,
                      width: maxLabelWidth, height: rowH ) )

            let vStr = NSAttributedString( string: values[ i ],
                                       attributes: valueAttrsList[ i ] )
            vStr.draw(
              in: CGRect( x: valueX, y: yPos,
                      width: valueWidth, height: rowH ) )

            yPos += rowH + 2
          }

          yPos += 8

          drawHorizontalLine(
            from: CGPoint( x: margin, y: yPos ),
              to: CGPoint( x: pageRect.width - margin, y: yPos ),
           color: .lightGray,
           width: 0.5 )
          yPos += 8

        } // for track

      } // writePDF

      return tempURL
    }
    catch
    {
      return nil
    }

  } // generate


  //-----------------------------------------------------------
  private static func drawHorizontalLine(
    from startP : CGPoint,
      to endP   : CGPoint,
   color colorP : UIColor,
   width widthP : CGFloat )
  {
    let path = UIBezierPath()
    path.move( to: startP )
    path.addLine( to: endP )
    colorP.setStroke()
    path.lineWidth = widthP
    path.stroke()

  } // drawHorizontalLine

} // PlaylistPDFGenerator


//--------------------------------------------
// A SwiftUI wrapper around UIActivityViewController so the
// standard share sheet can be presented for the generated PDF.
//--------------------------------------------
struct PlaylistPDFShareSheet : UIViewControllerRepresentable
{
  let activityItems : [Any]

  func makeUIViewController( context: Context ) -> UIActivityViewController
  {
    return UIActivityViewController(
              activityItems: activityItems,
        applicationActivities: nil )
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
              context: Context )
  {
  }

} // PlaylistPDFShareSheet
//--------------------------------------------
