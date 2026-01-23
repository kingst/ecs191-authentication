# Food analysis server

With this feature, we are going to create a new API endpoint where
authenticated users can post jpeg images and our server will return
information about the food in that image. In particular, we will
return:

  - Calorie estimate

  - Carbohydrate estimate

  - Protein estimate

  - Short summary of the food. For example, "burger and fries" or
    "spaghetti with meat sauce"

## APIs

We will need two APIs for this feature: an API for getting signed URLs
that callers can use to PUT an image to a Google Cloud Storage bucket
and an API for passing in the URL for the image that does the actual
image analysis and returns the results.

Both APIs need to be authenticated, but for now we're not going to
worry about rate limits or upload limits.

### Signed URL API (GET)

This API doesn't require any arguments and returns a signed URL that
users can use to PUT an image directly. It will also return an image
ID that we can use to lookup that image. For the image ID, use
server-generated name of the image file and we will only return URL
safe image names.

### Food estimate API (GET)

This API appends the image ID to the path, which we use to fetch the
image from Google Cloud Storage. It returns a JSON object with:

```json
{
  calories: 100,
  carbohydrates_grams: 15,
  protein_grams: 75,
  description: "Eggs and bacon",
  confidence: "high", // can be "high", "medium", or "low"
  image_id: "1A32-3E4123-123F3.jpg" // the name is a URL safe UUID
}
```

## Google cloud storage

We setup a google cloud storage bucket named `ecs191-login-bucket`
where we will store our images. We will store them under the
`images/<user_id>/` directory at the top level of the bucket. The
<user_id> is the user_id for the authenticated user.

When a user creates a signed URL, we will create an image name for
them using a UUID with the format `<UUID>.jpg`. This is an
implementation detail, from the API pespective we return a URL safe
string, but this choice will help keep our implementation simple since
we don't need to use extra storage to map image IDs to storage
locations.

When we create signed URLs, the URL will be valid for 10 minutes.

## Image analysis

For image analysis, we're going to use Anthropic APIs. We will use
Sonnet version 4.5, provide the server with context and get configure
it to return JSON to us, which we can then pass back to the user.

All images should be jpeg images, but since these are uploaded directly
by clients we should confirm that they are jpeg images before sending
them to Anthropic by checking for the magic bytes in the data.

One additional item we want to get from Anthropic is a confidence in
their prediction, so let's ask it to assess this for us explicitly.

For authentication, we will add a `ANTHROPIC_API_KEY` value to our
`creds.py` file in the server.

### Details

  - Use the official Python SDK from anthropic

  - Use structured JSON output via the `response_format` parameter

  - Images need to be base64-encoded and sent with a media type image/jpeg
  
  - Prompt design: Use a system prompt (below) and send the image as a user message

  - Error handling: If we get an error from anthropic, pass it back through the API as a specific "anthropic" error type

  - Non food or low quality images: Return an error in this case

  - For the model, use claude-sonnet-4-5-20250514

### System prompt

You are a food nutrition analyst. Analyze the provided image and estimate its nutritional content.
                                                                
Return a JSON object with these fields:
  - is_food: boolean, true if the image contains identifiable food, false otherwise
  - calories: integer, estimated total calories (0 if is_food is false)
  - carbohydrates_grams: integer, estimated carbohydrates in grams (0 if is_food is false)
  - protein_grams: integer, estimated protein in grams (0 if is_food is false)
  - description: string, brief description of the food (e.g., "burger and fries"), or reason why analysis failed
  - confidence: string, one of "high", "medium", or "low"

Set is_food to false if:
  - The image does not contain food
  - The image is too blurry to analyze
  - The food is too obscured to estimate nutritional content
