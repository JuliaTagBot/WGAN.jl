include("models.jl")
include("utils.jl")
include("loss.jl")
using Knet, ArgParse, FileIO, Images

function main(args)
    s = ArgParseSettings()
    s.description = "WGAN Implementation in Knet"

    @add_arg_table s begin
        ("--usegpu"; action=:store_true; help="use GPU or not")
        ("--type"; arg_type=String; default="dcganbn"; help="Type of model one of: [dcganbn, mlpganbn, dcgan, mlpgan]")
        ("--procedure"; arg_type=String; default="gan"; help="Training procedure. gan or wgan")
        ("--zsize"; arg_type=Int; default=100; help="Noise vector dimension")
        ("--epochs"; arg_type=Int; default=20; help="Number of training epochs")
        ("--report"; arg_type=Int; default=500; help="Report loss in n iterations")
        ("--batchsize"; arg_type=Int; default=128; help="Minibatch Size")
        ("--lr"; arg_type=Any; default=0.0002; help="Learning rate")
        ("--opt"; arg_type=String; default="adam"; help="Optimizer, one of: [adam, rmsprop]")
        ("--leak"; arg_type=Any; default=0.2; help="LeakyReLU leak.")
    end

    isa(args, AbstractString) && (args=split(args))
    o = parse_args(args, s; as_symbols=true)

    atype = o[:usegpu] ? KnetArray{Float32} : Array{Float32}

    batchsize = o[:batchsize]
    procedure = o[:procedure]
    zsize = o[:zsize]
    numepoch = o[:epochs]
    modeltype = o[:type]
    leak = o[:leak]
    optimizer = o[:opt]
    lr = o[:lr]

    println("Minibatch Size: $batchsize")
    println("Training Procedure: $procedure")
    println("Model Type: $modeltype")
    println("Noise size: $zsize")
    println("Number of epochs: $numepoch")
    println("Using $optimizer with learning rate $lr")

    o[:usegpu] ? println("Using GPU") : println("Not using GPU (why)")

    println("Loading dataset")

    data = loadimgtensors("/home/cem/bedroom", (1,10))
    bsize = size(data)
    println("Dataset size: $bsize")

    # Get model from models.jl
    if modeltype == "dcganbn"
        model = dcganbnorm
    elseif modeltype == "dcgan"
        model = dcgan
    elseif modeltype == "mlpganbn"
        model = mlpganbnorm
    elseif modeltype == "mlpgan"
        model = mlpgan
    else
        throw(ArgumentError("Unknown model type."))
    end

    generator, discriminator = model(zsize, leak, atype)

    gparams, gforw = generator
    dparams, dforw = discriminator

    gnumparam = numparams(gparams)
    dnumparam = numparams(dparams)
    println("Generator # of Parameters: $gnumparam")
    println("Discriminator # of Parameters: $dnumparam")

    # Form optimiziers
    if optimizer == "adam"
        gopt = optimizers(gparams, Adam, lr=lr, beta1=0.5)
        dopt = optimizers(dparams, Adam, lr=lr, beta1=0.5)
    elseif opt == "rmsprop"
        gopt = optimizers(gparams, Rmsprop, lr=lr)
        dopt = optimizers(dparams, Rmsprop, lr=lr)
    else:
        throw(ArgumentError("Unknown optimizer"))
    end

    # Save first randomly generated image
    grid = generateimgs(gforw, gparams, zsize, atype)
    outfile = "rand.png"
    save(outfile, colorview(RGB, grid))

    println("Making minibatches")
    batches = minibatch4(data, batchsize, atype)

    gradfun = procedure == "gan" ? gangrad : gangrad # TODO: wgangrad
    ggradfun, dgradfun = gradfun(atype, gforw, dforw)

    println("Started Training...")
    for epoch in 1:numepoch
        gtotalloss = 0.0
        dtotalloss = 0.0
        for minibatch in batches
            z = samplenoise4(zsize, size(minibatch)[end], atype)
            ggrad, gloss = ggradfun(gparams, dparams, minibatch, z)
            dgrad, dloss = dgradfun(dparams, gparams, minibatch, z)
            update!(gparams, ggrad, gopt)
            update!(dparams, dgrad, dopt)
            gtotalloss += gloss * batchsize
            dtotalloss += dloss * batchsize
       end
       gtotalloss /= bsize[1]
       dtotalloss /= bsize[1]
       elapsed = 0
       println("Epoch $epoch took $elapsed: G Loss: $gtotalloss D Loss: $dtotalloss")
    end

    grid = generateimgs(gforw, gparams, zsize, atype)
    outfile = "trained.png"
    save(outfile, colorview(RGB, grid))

    println("Done. Exiting...")
    return 0
end

main("--usegpu")