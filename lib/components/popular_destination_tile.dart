import 'package:flutter/material.dart';

class DestinationTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final double rating;
  final VoidCallback onTap;
  final double? width;

  const DestinationTile({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.onTap,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    // Constant max height for the tile
    const maxHeight = 215.0;

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight, // Constrain the height to 280
        ),
        child: Container(
          width: width ?? screenSize.width * 0.4, // Responsive width
          margin: EdgeInsets.only(right: screenSize.width * 0.04, bottom: screenSize.height * 0.02),
          decoration: BoxDecoration(
            color: Colors.grey[900], // Dark tile background
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with constrained height
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      imageUrl,
                      height: maxHeight * 0.6, // Adjust image height to fit within the max height
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child; // Image has loaded
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Details
              Padding(
                padding: EdgeInsets.all(screenSize.width * 0.04), // Responsive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with ellipsis for overflow
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis, // Ensure ellipsis when the title overflows
                      maxLines: 1, // Limit to 1 line
                    ),
                    const SizedBox(height: 4),
                    // Description with ellipsis for overflow
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 2, // Limit to 2 lines for the description
                      overflow: TextOverflow.ellipsis, // Show ellipses when it overflows
                    ),
                    const SizedBox(height: 4),
                    // Price text with ellipsis if it overflows
                    Text(
                      "Price: $price",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis, // Show ellipses if the text overflows
                      maxLines: 1, // Limit price text to 1 line
                    ),
                    const SizedBox(height: 4),
                    // Rating row with ellipsis in case of overflow
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis, // Ensure ellipses if the text overflows
                          maxLines: 1, // Limit to 1 line
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
