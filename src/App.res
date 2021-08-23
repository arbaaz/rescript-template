%%raw(`import './App.css'`)

module Urls = {
  type t = {
    id: string,
    url: string,
  }

  let decode = (data: Js.Json.t) => {
    id: Json.Decode.field("id", Json.Decode.string, data),
    url: Json.Decode.field("download_url", Json.Decode.string, data),
  }
}

module ImageCollection = {
  type t = array<Urls.t>
  let decode = Json.Decode.array(Urls.decode)
}

type action =
  | AskInitData
  | ApiLoading
  | ApiSuccess(ImageCollection.t)

type state = {data: AsyncData.t<ImageCollection.t>}
let initialState = {
  data: AsyncData.NotAsked,
}

@react.component
let make = () => {
  let (state, send) = ReactUpdate.useReducer((state, action) => {
    switch action {
    | AskInitData =>
      ReactUpdate.SideEffects(
        ({send}) => {
          ApiLoading -> send
          Fetch.fetch("https://picsum.photos/v2/list/")
          ->Promise.then(Fetch.Response.json)
          ->Promise.thenResolve(res => {
            res->ImageCollection.decode->ApiSuccess->send
          })
          ->ignore
          None
        },
      )
    | ApiLoading => ReactUpdate.Update({data: AsyncData.Loading})
    | ApiSuccess(data) => ReactUpdate.Update({data: AsyncData.Done(data)})
    }
  }, initialState)

  React.useEffect0(() => {
    AskInitData->send
    None
  })

  <div
    className="grid gap-2 sm:gap-10 grid-cols-2 sm:grid-cols-3 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
    {state.data
    ->AsyncData.map(x =>
      Belt.Array.map(x, item =>
        <img
          className="justify-self-center h-full w-full object-cover object-center rounded-lg cursor-pointer"
          key={item.id}
          src={item.url}
        />
      )->React.array
    )
    ->AsyncData.getWithDefault(<div> {"NotAsked | Loading"->React.string} </div>)
    }
  </div>
}
